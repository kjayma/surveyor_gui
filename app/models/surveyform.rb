class Surveyform < Survey
    def self.search(search)
      if search
        where('title LIKE ?', "%#{search}%")
      else
        scoped
      end
    end
end


