module RedmineRemoteGit
  # Loads the plugin stylesheet on every page so the top-menu Git icon renders
  # everywhere, not only on the overview page itself.
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
      stylesheet_link_tag('remote_git', plugin: 'redmine_remote_git')
    end
  end
end
