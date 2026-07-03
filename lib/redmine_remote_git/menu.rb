module RedmineRemoteGit
  # Reads the plugin Setting fresh (not the memoized RemoteGitService.settings) so
  # an admin's visibility change takes effect without an app restart.
  def self.plugin_settings
    if defined?(Setting) && Setting.respond_to?(:plugin_redmine_remote_git)
      Setting.plugin_redmine_remote_git || {}
    else
      {}
    end
  end

  # Whether the given user may see the top-menu Git entry / open the overview.
  # Modes (setting 'menu_visibility'): 'everyone' (default), 'admins', 'selected'.
  # 'selected' grants access to admins, to members of 'menu_group_ids', and to
  # users listed in 'menu_user_ids'.
  def self.menu_visible?(user)
    return false unless user && user.logged?
    s = plugin_settings
    case s['menu_visibility'].to_s
    when 'admins'
      user.admin?
    when 'selected'
      return true if user.admin?
      gids = Array(s['menu_group_ids']).map(&:to_i)
      uids = Array(s['menu_user_ids']).map(&:to_i)
      uids.include?(user.id) || (user.group_ids & gids).any?
    else
      true
    end
  end
end
