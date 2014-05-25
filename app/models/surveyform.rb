class Surveyform < Survey
    def self.search(search)
      search ? where('title LIKE ?', "%#{search}%") : all
    end
end


