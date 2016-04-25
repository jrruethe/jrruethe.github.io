---
layout: post
title: "Dockerfile Generator"
date: 2015-09-20 15:19:17 -0400
comments: true
toc: true
categories: 
 - Docker
 - Ruby
---

A lot of the Dockerfiles I write use the same template and tricks. I decided to write a ruby script to generate my Dockerfiles for me based on a minimal amount of input. I did this for a couple reasons:

 - I wanted my images to be as small as possible
 - I wanted consistent and readable Dockerfiles
 - I wanted to make it easy to update my images
 - I wanted all my images to be easy to port to the Raspberry Pi

{% more %}

# Dockerfile Tricks

## Keeping the image small

Every command in a Dockerfile causes a layer to be committed. Once a layer is committed, files on that layer can be hidden, but not deleted. For that reason, it becomes advantageous to run multiple commands at a time. For example, don't do this:

{% codeblock lang:bash %}
RUN apt-get update
RUN apt-get install -y build_essential
RUN apt-get clean
{% endcodeblock %}

Line 2 will download a bunch of packages and install them. Line 3 attempts to clean up the packages that were downloaded, but it's too late; they were already committed to the layer and can only be hidden. The overall image will be large because that layer still needs to be downloaded.

A better approach is:

{% codeblock lang:bash %}
RUN apt-get update && \
    apt-get install -y build_essential && \
    apt-get clean
{% endcodeblock %}

This will run all three commands and apply the end result to a single layer, greatly reducing the image size.

### The ADD command

The `ADD` command hinders our ability to keep the image small, because it will commit files to a layer without giving a chance to delete those files later. This is fine for files that are supposed to be permanently in the image, but what about temporary files? For example:

{% codeblock lang:bash %}
ADD some_package.deb /

RUN dpkg -i /some_package.deb && \
    rm -f /some_package.deb
{% endcodeblock %}

The package removal will only hide the file; the image still contains the data on a lower layer.

Instead, a better approach is to run a web server and download temporary files to your image, allowing the same `RUN` statement to later delete the temporary files. To do this, start a server before building your image:

    python -m SimpleHTTPServer 8888
    
Then do the following in your Dockerfile:

{% codeblock lang:bash %}
RUN wget http://<ip_address>:8888/package.deb && \
    (dpkg -i package.deb || true) && \
    apt-get -y -f install --no-install-recommends && \
{% endcodeblock %}

Replace `<ip_address>` with your *internal* ip address. To get that, use the following command:

    ip route get 8.8.8.8 | awk '{print $NF; exit}'

## Keeping the Dockerfile readable

From the previous section, it stands to reason that putting all the commands on a single `RUN` statement will yield the smallest image (assuming you clean up after yourself). If there are a lot of commands, it can be difficult to read what is going on.

One trick is to interleave comments into the `RUN` statement by using backticks. Another common thing to do is add blank lines using backslashes, and align all the backslashes to the right:

{% codeblock lang:bash %}
RUN `# Update package list`             && \
     apt-get update                     && \
                                           \
    `# Install development tools`       && \
     apt-get install -y build_essential && \
                                           \
    `# Delete cached packages`          && \
     apt-get clean
{% endcodeblock %}

The result is much more readable, but it is tedious to make sure all the spacing is correct.

# Dockerfile Generator

Incorporating the above tricks, I wrote a Dockerfile generator to quickly create Dockerfiles for simple projects:

{% codeblock lang:ruby %}
#!/usr/bin/env ruby

# dockerfile-generator.rb
# Copyright (C) 2015 Joe Ruether jrruethe@gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

require "set"
require "yaml"

class Dockerfile
  
  def initialize

    @from       = "phusion/baseimage:0.9.16"
    @maintainer = "Joe Ruether"    
    @user       = "user"
    @service    = nil
    
    @requirements = Set.new
    @packages     = Set.new
    @volumes      = Set.new
    @ports        = Set.new
    
    # Files to add before and after the run command
    @adds       = []
    @configures = []
    
    # Command lists for the run section
    @begin_commands        = []
    @pre_install_commands  = []
    @install_commands      = []
    @post_install_commands = []
    @run_commands          = []
    @end_commands          = []
    
    # Set if deb packages need dependencies to be resolved
    @deb_flag = false
    
    # Used to download deb files from the host  
    @ip_address = `ip route get 8.8.8.8 | awk '{print $NF; exit}'`.chomp
  end
  
  ##############################################################################
  public
  
  # string ()
  def finalize
    lines = []
    lines.push "FROM #{@from}"
    lines.push "MAINTAINER #{@maintainer}"
    lines.push ""
    @ports.each{|p| lines.push "EXPOSE #{p}"}
    lines.push "" if !@ports.empty?
    lines += @adds
    lines.push "" if !@adds.empty?
    lines.push build_run_command
    lines.push ""
    lines += @configures
    lines.push "" if !@configures.empty?
    @volumes.each{|v| lines.push "VOLUME #{v}"}
    lines.push "" if !@volumes.empty?
    lines.push "ENTRYPOINT [\"/sbin/my_init\"]"
  end
  
  # void (string)
  def set_user(user)
    @user = user
    add_begin_command comment "Adjusting user permissions"
    add_begin_command "usermod -u 1000 #{user} && groupmod -g 1000 #{user}"
    add_begin_command blank
  end
  
  # void (string)
  def set_service(service)
    @service = service
  end
  
  # void (string, string)
  def add(source, destination = "/")
    @adds.push "ADD #{source} #{destination}"
  end
  
  # void (string, string)
  def configure(source, destination = "/")
    @configures.push "ADD #{source} #{destination}"
  end
  
  # void (int)
  def expose(port)
    @ports.add port
  end
  
  # void (string, string, string)
  def add_repository(name, deb, key = nil)
    add_pre_install_command comment "Adding #{name} repository"
    add_pre_install_command "wget -O - #{key} | apt-key add -" if key
    add_pre_install_command "echo '#{deb}' >> /etc/apt/sources.list.d/#{name.downcase}.list"
    add_pre_install_command blank
    
    @requirements.add "wget"
    @requirements.add "ssl-cert"
  end
  
  # void (string, string)
  def add_ppa(name, ppa)
    add_pre_install_command comment "Adding #{name} PPA"
    add_pre_install_command "add-apt-repository -y #{ppa}"
    add_pre_install_command blank
    
    @requirements.add "software-properties-common"
    @requirements.add "python-software-properties"
  end
  
  # void (string)
  def install_package(package)
    @packages.add package
  end
  
  # void (string)
  def install_deb(deb)
    add_install_command comment "Installing deb package"
    add_install_command "wget http://#{@ip_address}:8888/#{deb}"
    add_install_command "(dpkg -i #{deb} || true)"
    add_install_command blank
    add_post_install_command "rm -f #{deb}"
    
    @packages.add "wget"
    @deb_flag = true
  end
    
  # void (string)
  def run(command)
    command.strip!
    if command.start_with? "#"
      add_run_command comment command[1..-1].strip
    elsif command.match /^\s*$/
      add_run_command blank
    else
      add_run_command command
    end
  end
  
  # void (string)
  def add_volume(volume)
    add_end_command comment "Fixing permission errors for volume"
    add_end_command "chown -R #{@user}:#{@user} #{volume}"
    add_end_command blank
    
    @volumes.add volume
  end
  
  ##############################################################################
  private
  
  # string (string)
  def comment(string)
    "`\# #{string}`"
  end
  
  # string ()
  def blank
    "\\"
  end
    
  # [string] ([string])
  def build_install_command(packages)
    
    # Convert the set to an array
    packages = packages.to_a
    
    # Specify the command
    command = "apt-get install -y --no-install-recommends"
      
    # Make an array of paddings
    lines = [" " * command.length()] * packages.length
      
    # Overwrite the first line with the command
    lines[0] = command
    
    # Append the packages and backslashes to each line
    lines = lines.zip(packages).collect{|l, p| l += " #{p} \\"}
      
    # Convert the backslash on the last line to "&& \"
    lines[-1] = lines[-1][0..-2] + "&& \\"
    
    # Add comment and blank
    lines.insert(0, comment("Installing packages"))
    lines.push blank
  end
    
  # string ()
  def build_run_command
    
    lines = []
    
    # Any packages that were requirements can be removed from the packages list
    @packages = @packages.difference @requirements
      
    lines += begin_commands
    
      # If required packages were specified
    if !@requirements.empty?
      # Update the package list
      lines.push comment "Updating Package List"
      lines.push "apt-get update"
      lines.push blank

      # Install requirements
      lines += build_install_command @requirements
    end
    
    # Run pre-install commands
    lines += pre_install_commands
        
    # Add apt-cacher proxy
    lines.push comment "Adding apt-cacher-ng proxy"
    lines.push "echo 'Acquire::http { Proxy \"http://172.17.42.1:3142\"; };' > /etc/apt/apt.conf.d/01proxy"
    lines.push blank
    
    # Update
    lines.push comment "Updating Package List"
    lines.push "apt-get update"
    lines.push blank
    
    # Install packages
    lines += build_install_command @packages unless @packages.empty?
    
    # Run install commands
    lines += install_commands
    
    # If manual deb packages were specified
    if @deb_flag
      # Resolve their dependencies
      lines.push comment "Installing deb package dependencies"
      lines.push "apt-get -y -f install --no-install-recommends"
      lines.push blank
    end
    
    # Run post-install commands
    if !@post_install_commands.empty?
      lines.push comment "Removing temporary files"
      lines += post_install_commands
      lines.push blank
    end
    
    # Clean up
    lines.push comment "Cleaning up after installation"
    lines.push "apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"
    lines.push blank
    
    # Remove apt-cacher proxy
    lines.push comment "Removing apt-cacher-ng proxy"
    lines.push "rm -f /etc/apt/apt.conf.d/01proxy"
    lines.push blank
    
    # Run commands
    lines += run_commands
    lines.push blank if !@run_commands.empty?
    
    # Enable service on startup
    if @service
      lines.push comment "Enable service on startup"
      lines.push "sed -i \"s@exit 0@service #{@service} start@g\" /etc/rc.local"
      lines.push blank
    end
    
    # End commands
    lines += end_commands
    
    # Determine the longest line
    longest_length = lines.max_by(&:length).length
    
    # For each line
    lines.collect do |l|
      
      # Determine how many spaces needed to indent
      length_to_extend = longest_length - l.length
      
      # Indent the line
      length_to_extend += 1 if l.start_with? "`"
      l.insert(0, " " * (l.start_with?("`") ? 4 : 5))
      
      # Add or Extend end markers 
      if l.end_with? " && \\"
        length_to_extend += 5
        l.insert(-6, " " * length_to_extend)
      elsif l.end_with? " \\"
        length_to_extend += 5
        l.insert(-3, " " * length_to_extend)
      else
        l.insert(-1, " " * length_to_extend)
        l.insert(-1, " && \\")
      end
      
    end
    
    # First line should start with "RUN"
    lines[0][0..2] = "RUN"
    
    # Last line should not end with marker
    lines[-1].gsub! " && \\", ""
    lines[-1].gsub! " \\", ""
    
    # Last line might be blank now, do it again
    if lines[-1].match /^\s*$/
      lines.delete_at -1
      
      # Last line should not end with marker
      lines[-1].gsub! " && \\", ""
      lines[-1].gsub! " \\", ""
    end
      
    # Make a string
    lines.join "\n"
    
  end
  
  ##############################################################################

  # Some metaprogramming to handle the various command lists
  def self.handle(arg)
    self.class_eval("def #{arg};@#{arg};end")
    self.class_eval("def add_#{arg[0..-2]}(val);@#{arg}.push val;end")
  end
  
  handle :begin_commands
  handle :pre_install_commands
  handle :install_commands
  handle :post_install_commands
  handle :run_commands
  handle :end_commands
    
end

################################################################################
# Parse Dockerfile.yml

dockerfile = Dockerfile.new
yaml = YAML::load_file("Dockerfile.yml")

# Parse User tag
dockerfile.set_user yaml["User"] if yaml.has_key? "User"

# Parse Service tag
dockerfile.set_service yaml["Service"] if yaml.has_key? "Service"
  
# Parse Add tag
yaml["Add"].each do |i| 
  if i.is_a? Hash
    dockerfile.add i.first[0], i.first[1]
  else
    dockerfile.add i
  end
end if yaml.has_key? "Add"

# Parse Repositories tag
yaml["Repositories"].each do |r|
  if r["URL"].start_with? "deb "
    dockerfile.add_repository(r["Name"], r["URL"], r["Key"])
  elsif r["URL"].start_with? "ppa:"
    dockerfile.add_ppa(r["Name"], r["URL"])
  end
end if yaml.has_key? "Repositories"

# Parse Install tag
yaml["Install"].each do |package|
  if package.end_with? ".deb"
    dockerfile.install_deb package
  else
    dockerfile.install_package package
  end
end if yaml.has_key? "Install"

# Parse Run tag
yaml["Run"].split("\n").each do |line|
  dockerfile.run line
end if yaml.has_key? "Run"

# Parse Configure tag
yaml["Configure"].each do |i| 
  if i.is_a? Hash
    dockerfile.add i.first[0], i.first[1]
  else
    dockerfile.add i
  end
end if yaml.has_key? "Configure"

# Parse Expose tag
yaml["Expose"].each do |port|
  dockerfile.expose port
end if yaml.has_key? "Expose"

# Parse Volumes tag
yaml["Volumes"].each do |volume|
  dockerfile.add_volume volume
end if yaml.has_key? "Volumes"

# Output Dockerfile
puts dockerfile.finalize

{% endcodeblock %}

Run it from a directory that contains a `Dockerfile.yml` and it will print out a Dockerfile:

    ruby dockerfile-generator.rb > Dockerfile

## Dockerfile.yml Specifications

A simplified Dockerfile specification can be put into `Dockerfile.yml`. The supported items are explained below. All items are optional.

{% codeblock lang:yaml %}
# Specify a user that the service will run as, used for fixing permissions on volumes.
User: www-data

# Specify the service that will run on startup.
Service: apache2

# Adds a file to / or the specified destination.
# Tar files are automatically unpacked.
# Remote files are allowed.
# Files are added before any commands are run.
Add:
 - root_filesystem.tar
 - Foo.txt : /home/user/
 - http://www.foo.com/Foo.txt : /home/user/bar.txt

# Add Repositories and PPAs.
# URLs are either a complete deb line in sources.list format or a PPA.
# Keys are optional.
Repositories:
 - Name: Owncloud
   URL : deb http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_14.04/ /
   Key : http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_14.04/Release.key
   
 - Name: Bitcoin
   URL : ppa:bitcoin/bitcoin

# Install packages or deb files.
Install:
 - build_essential
 - some_package.deb
 
# Run commands verbatim in bash format. Note the pipe character.
Run: |
 # This is a comment
 echo Hello
 
 # Another comment
 rm -rf /

# Exactly the same as Add, however files are added AFTER commands are run.
Configure:
 - root_filesystem.tar
 - Foo.txt : /home/user/
 - http://www.foo.com/Foo.txt : /home/user/bar.txt

# Ports to expose.
Expose:
 - 80
 - 443

# Volumes to expose to the host.
Volumes:
 - /var/www/owncloud
 - /mnt
{% endcodeblock %}

## Examples

Making a Dockerfile is really easy with this generator. The generated Dockerfile will automatically use an `apt-cacher-ng` container for downloading packages, which is handy if you are making a lot of images or rebuilding often. Therefore, remember to run the `apt-cacher-ng` container before building other images. Also remember to run the python web server if you are installing deb packages manually.

### Apt-cacher-ng

First step is to create the `apt-cacher-ng` image so it can be used to build other images. Below is the `Dockerfile.yml`:

{% codeblock lang:yaml %}
User   : apt-cacher-ng
Service: apt-cacher-ng

Install:
 - apt-cacher-ng
 
Expose: 
 - 3142
  
Volumes:
 - /var/cache/apt-cacher-ng
{% endcodeblock %}

Thats it! Generating the Dockerfile yields (scroll to the right to see the `&& \` markers):

{% codeblock lang:bash %}
FROM phusion/baseimage:0.9.16
MAINTAINER Joe Ruether

EXPOSE 3142

RUN `# Adjusting user permissions`                                                            && \
     usermod -u 1000 apt-cacher-ng && groupmod -g 1000 apt-cacher-ng                          && \
                                                                                                 \
    `# Adding apt-cacher-ng proxy`                                                            && \
     echo 'Acquire::http { Proxy "http://172.17.42.1:3142"; };' > /etc/apt/apt.conf.d/01proxy && \
                                                                                                 \
    `# Updating Package List`                                                                 && \
     apt-get update                                                                           && \
                                                                                                 \
    `# Installing packages`                                                                   && \
     apt-get install -y --no-install-recommends apt-cacher-ng                                 && \
                                                                                                 \
    `# Cleaning up after installation`                                                        && \
     apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*                           && \
                                                                                                 \
    `# Removing apt-cacher-ng proxy`                                                          && \
     rm -f /etc/apt/apt.conf.d/01proxy                                                        && \
                                                                                                 \
    `# Enable service on startup`                                                             && \
     sed -i "s@exit 0@service apt-cacher-ng start@g" /etc/rc.local                            && \
                                                                                                 \
    `# Fixing permission errors for volume`                                                   && \
     chown -R apt-cacher-ng:apt-cacher-ng /var/cache/apt-cacher-ng                           

VOLUME /var/cache/apt-cacher-ng

ENTRYPOINT ["/sbin/my_init"]
{% endcodeblock %}

Since it obviously cannot use `apt-cacher-ng` to build itself, simply remove those lines for this image:

{% codeblock lang:bash %}
FROM phusion/baseimage:0.9.16
MAINTAINER Joe Ruether

EXPOSE 3142

RUN `# Updating Package List`                                                                 && \
     apt-get update                                                                           && \
                                                                                                 \
    `# Installing packages`                                                                   && \
     apt-get install -y --no-install-recommends apt-cacher-ng                                 && \
                                                                                                 \
    `# Cleaning up after installation`                                                        && \
     apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*                           && \
                                                                                                 \
    `# Enable service on startup`                                                             && \
     sed -i "s@exit 0@service apt-cacher-ng start@g" /etc/rc.local                            && \
                                                                                                 \
    `# Fixing permission errors for volume`                                                   && \
     chown -R apt-cacher-ng:apt-cacher-ng /var/cache/apt-cacher-ng                           

VOLUME /var/cache/apt-cacher-ng

ENTRYPOINT ["/sbin/my_init"]
{% endcodeblock %}

### Owncloud

Lets try something a little more complicated. Here, I present two Owncloud images. The first one is built using the latest code in the repository, while the second is built with specifically downloaded versions of deb files. 

#### Latest From Repository

Dockerfile.yml:

{% codeblock lang:yaml %}
User   : www-data
Service: apache2

Repositories:
 - Name: Owncloud
   URL : deb http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_14.04/ /
   Key : http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_14.04/Release.key

Install:
 - owncloud

Run: |
 # Enable SSL
 a2enmod ssl && a2ensite default-ssl
 
Expose: 
 - 443
  
Volumes:
 - /var/www/owncloud
 - /mnt
{% endcodeblock %}

Generated Dockerfile:

{% codeblock lang:bash %}
FROM phusion/baseimage:0.9.16
MAINTAINER Joe Ruether

EXPOSE 443

RUN `# Updating Package List`                                                                                                                && \
     apt-get update                                                                                                                          && \
                                                                                                                                                \
    `# Installing packages`                                                                                                                  && \
     apt-get install -y --no-install-recommends wget                                                                                            \
                                                ssl-cert                                                                                     && \
                                                                                                                                                \
    `# Adding Owncloud repository`                                                                                                           && \
     wget -O - http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_14.04/Release.key | apt-key add -                    && \
     echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_14.04/ /' >> /etc/apt/sources.list.d/owncloud.list && \
                                                                                                                                                \
    `# Adding apt-cacher-ng proxy`                                                                                                           && \
     echo 'Acquire::http { Proxy "http://172.17.42.1:3142"; };' > /etc/apt/apt.conf.d/01proxy                                                && \
                                                                                                                                                \
    `# Updating Package List`                                                                                                                && \
     apt-get update                                                                                                                          && \
                                                                                                                                                \
    `# Installing packages`                                                                                                                  && \
     apt-get install -y --no-install-recommends owncloud                                                                                     && \
                                                                                                                                                \
    `# Cleaning up after installation`                                                                                                       && \
     apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*                                                                          && \
                                                                                                                                                \
    `# Removing apt-cacher-ng proxy`                                                                                                         && \
     rm -f /etc/apt/apt.conf.d/01proxy                                                                                                       && \
                                                                                                                                                \
    `# Enable SSL`                                                                                                                           && \
     a2enmod ssl && a2ensite default-ssl                                                                                                     && \
                                                                                                                                                \
    `# Enable service on startup`                                                                                                            && \
     sed -i "s@exit 0@service apache2 start@g" /etc/rc.local                                                                                 && \
                                                                                                                                                \
    `# Fixing permission errors for volume`                                                                                                  && \
     chown -R www-data:www-data /var/www/owncloud                                                                                            && \
                                                                                                                                                \
    `# Fixing permission errors for volume`                                                                                                  && \
     chown -R www-data:www-data /mnt                                                                                                        

VOLUME /var/www/owncloud
VOLUME /mnt

ENTRYPOINT ["/sbin/my_init"]
{% endcodeblock %}

#### Specific Version

Dockerfile.yml:

{% codeblock lang:yaml %}
User   : www-data
Service: apache2

Install:
 - owncloud_8.1.3-13.1_all.deb
 - owncloud-server_8.1.3-13.1_all.deb
 - owncloud-config-apache_8.1.3-13.1_all.deb

Run: |
 # Enable SSL
 a2enmod ssl && a2ensite default-ssl
 
Expose: 
 - 443
  
Volumes:
 - /var/www/owncloud
 - /mnt
{% endcodeblock %}

Generated Dockerfile:

{% codeblock lang:bash %}
FROM phusion/baseimage:0.9.16
MAINTAINER Joe Ruether

EXPOSE 443

RUN `# Adding apt-cacher-ng proxy`                                                            && \
     echo 'Acquire::http { Proxy "http://172.17.42.1:3142"; };' > /etc/apt/apt.conf.d/01proxy && \
                                                                                                 \
    `# Updating Package List`                                                                 && \
     apt-get update                                                                           && \
                                                                                                 \
    `# Installing packages`                                                                   && \
     apt-get install -y --no-install-recommends wget                                          && \
                                                                                                 \
    `# Installing deb package`                                                                && \
     wget http://192.168.1.106:8888/owncloud_8.1.3-13.1_all.deb                               && \
     (dpkg -i owncloud_8.1.3-13.1_all.deb || true)                                            && \
                                                                                                 \
    `# Installing deb package`                                                                && \
     wget http://192.168.1.106:8888/owncloud-server_8.1.3-13.1_all.deb                        && \
     (dpkg -i owncloud-server_8.1.3-13.1_all.deb || true)                                     && \
                                                                                                 \
    `# Installing deb package`                                                                && \
     wget http://192.168.1.106:8888/owncloud-config-apache_8.1.3-13.1_all.deb                 && \
     (dpkg -i owncloud-config-apache_8.1.3-13.1_all.deb || true)                              && \
                                                                                                 \
    `# Installing deb package dependencies`                                                   && \
     apt-get -y -f install --no-install-recommends                                            && \
                                                                                                 \
    `# Removing temporary files`                                                              && \
     rm -f owncloud_8.1.3-13.1_all.deb                                                        && \
     rm -f owncloud-server_8.1.3-13.1_all.deb                                                 && \
     rm -f owncloud-config-apache_8.1.3-13.1_all.deb                                          && \
                                                                                                 \
    `# Cleaning up after installation`                                                        && \
     apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*                           && \
                                                                                                 \
    `# Removing apt-cacher-ng proxy`                                                          && \
     rm -f /etc/apt/apt.conf.d/01proxy                                                        && \
                                                                                                 \
    `# Enable SSL`                                                                            && \
     a2enmod ssl && a2ensite default-ssl                                                      && \
                                                                                                 \
    `# Enable service on startup`                                                             && \
     sed -i "s@exit 0@service apache2 start@g" /etc/rc.local                                  && \
                                                                                                 \
    `# Fixing permission errors for volume`                                                   && \
     chown -R www-data:www-data /var/www/owncloud                                             && \
                                                                                                 \
    `# Fixing permission errors for volume`                                                   && \
     chown -R www-data:www-data /mnt                                                         

VOLUME /var/www/owncloud
VOLUME /mnt

ENTRYPOINT ["/sbin/my_init"]
{% endcodeblock %}

As you can see, this script is pretty handy for quickly creating Docker images that are consistent and readable while maintaining a small image size.
