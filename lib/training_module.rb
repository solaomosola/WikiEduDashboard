# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/training_base"
require_dependency "#{Rails.root}/lib/training_library"

class TrainingModule < TrainingBase
  attr_accessor :name, :slides, :description, :estimated_ttc, :id, :wiki_page
  alias raw_slides slides

  #################
  # Class methods #
  #################
  def self.find(id)
    all.detect { |training_module| training_module.id == id }
  end

  def self.cache_key
    'modules'
  end

  def self.path_to_yaml
    "#{base_path}/modules/*.yml"
  end

  def self.wiki_base_page
    ENV['training_modules_wiki_page']
  end

  def self.trim_id_from_filename
    false
  end

  # This reloads all the library and module content, but only updates the slides
  # for the module with the given slug.
  def self.reload_module(slug:)
    # First reload the libraries and modules so we have the new list of slugs
    # and can load slides for brand-new modules.
    TrainingLibrary.flush
    TrainingModule.flush
    TrainingLibrary.load
    TrainingModule.load
    # Reload the requested module's slides
    training_module = TrainingModule.find_by(slug: slug)
    raise ModuleNotFound, "No module #{slug} found!" unless training_module
    TrainingSlide.load(slug_whitelist: training_module.slide_slugs)

    # After updating the module's slides, we must flush and update the module
    # cache again so that it includes the updated slides.
    TrainingModule.flush
    TrainingModule.load
  end
  ####################
  # Instance methods #
  ####################

  # raw_slides can be called to access the string representation;
  # #slides now returns the instances of TrainingSlide
  def slides
    return @sorted_slides if @sorted_slides.present?
    selected_slides = TrainingSlide.where(slug: slide_slugs)
    @sorted_slides = selected_slides.sort do |a, b|
      slide_slugs.index(a.slug) <=> slide_slugs.index(b.slug)
    end
  end

  def valid?
    required_attributes = [id, name, slug, description, raw_slides]
    required_attributes.all?
  end

  def slide_slugs
    @slide_slugs ||= raw_slides.map(&:slug)
  end

  class ModuleNotFound < StandardError; end
end
