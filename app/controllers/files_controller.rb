class FilesController < ApplicationController
  layout false

  def index
    @files = all_files(params[:extension])
    if params[:query].present?
      @files = @files.select { |f| f.downcase.match?(/.*#{Regexp.escape(params[:query].downcase).split('').join('.*')}.*/) }
    end
    @files = @files.first(10)
  end

  private

  def all_files(extension)
    Rails.cache.fetch("all_files::#{root_path}::#{extension}::#{File.mtime(root_path)}", expires_in: 1.hour) do
      result = Dir["#{root_path}**/*"]
      if extension.present?
        result.select! { |f| f.end_with?(extension) }
      else
        result.select! { |f| File.directory?(f) }
      end
      result.map! { |f| f.split(root_path).last }
    end
  end

  def root_path
    @root_path ||=
      case params[:root].to_s
      when '' then "#{ENV['HOME']}/"
      when 'components' then "#{Rails.root.join('components')}/"
      else
        "#{ENV['HOME']}/#{Rails.cache.read("#{params[:root]}_path")}/"
      end
  end
end
