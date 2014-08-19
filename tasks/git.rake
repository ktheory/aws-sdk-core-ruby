def version
  verison = ENV['VERSION'].to_s.sub(/^v/, '')
  if version.empty?
    warn("usage: VERSION=x.y.z rake release:tag")
    exit
  end
  version
end

task 'git:require_clean_workspace' do
  # Ensure the git repo is free of unstaged or untracked files prior
  # to building / testing / pushing a release.
  unless `git diff --shortstat 2> /dev/null | tail -n1` == ''
    warn('workspace must be clean to release')
    exit(1)
  end
end

task 'git:tag' do
  sh("git commit -m \"Bumped version to v#{version}\"")
  sh("git tag -a -m \"$(rake git:tag_message)\" v#{version}")
end

task 'git:tag_message' do
  issues = `git log $(git describe --tags --abbrev=0)...HEAD -E --grep '#[0-9]+' 2>/dev/null`
  issues = issues.scan(/((?:\S+\/\S+)?#\d+)/).flatten
  msg = "Tag release v#{version}"
  msg << "\n\n"
  unless issues.empty?
    msg << "References:#{issues.uniq.sort.join(', ')}"
    msg << "\n\n"
  end
  msg << `rake changelog:latest`
  puts msg
end

task 'git:push' do
  sh('git push origin')
  sh('git push origin --tags')
  sh("gem push aws-sdk-core-#{version}.gem")
  #sh("gem push aws-sdk-resources-#{version}.gem")
  #sh("gem push aws-sdk-#{version}.gem")
end
