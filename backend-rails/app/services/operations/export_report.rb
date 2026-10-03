# frozen_string_literal: true

module Operations
  class ExportReport
    def self.call(election:, path:, version: nil)
      report = Voting::PublicReport.call(election: election, version: version)
      raise Voting::FinalReport::NotReady, 'Report is not published or election is annulled' unless report['status'] == 'final'

      File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
        file.write(JSON.pretty_generate(report) + "\n")
      end
      path
    end
  end
end
