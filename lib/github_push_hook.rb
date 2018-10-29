class GithubPushHook
  attr_accessor :original_hash, :hash

  def initialize(_original_hash)
    @original_hash = Hashie::Mash.new _original_hash
    @hash = Hashie::Mash.new GithubPushHook.clean_push_hook(@original_hash)
  end

  def initial_web_hook?
    original_hash[:zen].present?
  end

  def branch
    return original_hash[:repository][:default_branch] if initial_web_hook?

    hash[:ref].gsub(/^refs\/heads\//, "")
  end

  def sha
    hash[:after]
  end

  def repository_id
    original_hash[:repository][:id]
  end

  def self.clean_push_hook(hook)
    new_hook = {}
    keep = [
      :ref, :before, :after, :forced, :base_ref, 
      :compare, :head_commit, :pusher, 
    ]

    keep.each do |keepers|
      new_hook[keepers] = hook[keepers]
    end

    new_hook
  end
end
