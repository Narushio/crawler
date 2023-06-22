module Crawler
  class Azurlane
    def initialize(update_image_storage_path: nil)
      @base_url = "https://azurlane.koumakan.jp"
      @base_path = "resources/azurlane"
      @update_image_storage_path = update_image_storage_path
      @proxy = "http://127.0.0.1:7890"
      @next_gallery_url = nil
    end

    def download_wallpaper
      FileUtils.mkdir_p(@base_path + "/wallpaper") unless Dir.exist?(@base_path + "/wallpaper")
      main_doc = Nokogiri::HTML(Down.open(URI.join(@base_url, "wiki/Loading_Screens").to_s, proxy: @proxy))
      main_doc.css("a.image").each do |a_dom|
        filename = a_dom.attr("href").split(":").last
        destination = @base_path + "/wallpaper/#{filename}"
        store_original_file(destination, filename, a_dom.attr("href"))
      end
    end

    def download_gallery
      FileUtils.mkdir_p(@base_path + "/gallery") unless Dir.exist?(@base_path + "/gallery")
      loop do
        gallery_url = URI.join(@base_url, "wiki/Category:Skin_images").to_s
        gallery_url = @next_gallery_url if @next_gallery_url
        page_for_gallery(gallery_url)
        break unless @next_gallery_url
      end
    end

    private

    def page_for_gallery(gallery_url)
      main_doc = Nokogiri::HTML(Down.open(gallery_url, proxy: @proxy))
      a_doms = main_doc.css("a.image")
      store_threads = []
      a_doms.each_with_index do |a_dom, index|
        filename = CGI.unescape(a_dom.attr("href").split(":").last)
        destination = @base_path + "/gallery/#{filename}"
        if store_threads.size == 10
          store_threads.each(&:join)
          store_threads = []
        end
        store_threads << Thread.new { store_original_file(destination, filename, a_dom.attr("href")) }
        if (index + 1) == a_doms.size
          gallery_hrefs = main_doc.css("a[title='Category:Skin images']").map { _1.attr("href") }.uniq
          href = gallery_hrefs.find { _1.match?("filefrom") }
          @next_gallery_url = href ? URI.join(@base_url, href).to_s : nil
        end
      end
      store_threads.each(&:join) unless store_threads.empty?
    end

    def store_original_file(destination, filename, href)
      unless File.exist?(destination)
        begin
          file_doc = Nokogiri::HTML(Down.open(URI.join(@base_url, href).to_s, proxy: @proxy))
          file_url = file_doc.css("a.internal").attr("href")
          Down.download(file_url, destination: destination, proxy: @proxy)
          if @update_image_storage_path
            filepath = destination.sub(@base_path, @update_image_storage_path)
            target_path = filepath.split("/")[..-2].join("/")
            FileUtils.mkdir_p(target_path) unless Dir.exist?(target_path)
            FileUtils.cp(destination, target_path)
          end
          puts "[INFO]#{filename} downloaded successfully at #{Time.now}"
        rescue => e
          puts "[ERROR]#{e.inspect}"
          sleep 5
          retry
        end
      end
    end
  end
end
