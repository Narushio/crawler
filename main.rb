require "./lib/crawler"
crawler = Crawler::Azurlane.new(update_image_storage_path: "resources/azurlane_#{Date.today.to_s.tr("-", "_")}")
crawler.download_wallpaper
crawler.download_gallery
