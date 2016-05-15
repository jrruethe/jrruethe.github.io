# Title: Github Repos Octopress
# Embed a GitHub repository - info and download button
#
# by: Eric F (iEFdev)
# Source URL: https://github.com/iEFdev/github-repos-octopress
#
# Usage:
#	{% githubrepo <username>/<reponame> %}
#	{% githubrepo octocat/Spoon-Knife %}
#
#
# To activate the script. Add to the head in your post:
#
#	githubrepos: true
#
# Example:
# ---
# layout: post
# title: "Foo Bar Title"
#
#  // ... //
#
# comments: true
# githubrepos: true		<--- !!!
#---
#
# It's done this way so you don't load it every time, and don't
# have to think about to add it in your post.
#

module Jekyll
  class GitHubReposOctopress < Liquid::Tag

    def initialize(name, repo, tokens)
      super
      @repo = repo
      @repo.strip!
    end

    def render(context)
      %(<div class="github-widget" data-repo="#{@repo}"></div>)
    end
  end
end

Liquid::Template.register_tag('githubrepo', Jekyll::GitHubReposOctopress)
