#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'wikidata_ids_decorator'

require_relative 'lib/remove_notes'

require_relative 'lib/scraped_wikipedia_positionholders'
require_relative 'lib/wikipedia_candidates_page'
require_relative 'lib/wikipedia_candidate_row'


# The Wikipedia page with a list of election results
class Candidates < WikipediaCandidatesPage
  decorator RemoveNotes
  decorator WikidataIdsDecorator::Links

  def wanted_tables
    noko.xpath('.//table[.//tr[2]//th[contains(., "Candidate")]]')
  end
end

# Each candidate in each election
class Candidate < WikipediaCandidateRow
  def columns
    %w[_color party name]
  end

  field :election do
    noko.xpath('ancestor::table//tr[1]//a/@wikidata').map(&:text).first
  end

  field :electionLabel do
    noko.xpath('ancestor::table//tr[1]//a').map(&:text).map(&:tidy).first
  end

  field :votes do
    tds.map(&:text).map(&:tidy).reject(&:empty?).last.gsub(',', '')
  end

  # https://stackoverflow.com/a/6630486
  field :ranking do
    (tds[0].xpath('count(ancestor::tr) + count(ancestor::tr[1]/preceding-sibling::tr)') - 2).to_i
  end
end

url = ARGV.first
puts Scraped::Wikipedia::PositionHolders.new(url => Candidates).to_csv
