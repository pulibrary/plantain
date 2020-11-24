# frozen_string_literal: true
class AskAQuestionForm
  include ActiveModel::Model
  attr_accessor :name, :email, :subject, :message, :location_code, :context, :title

  validates :name, :email, :message, presence: true
  validates :email, email: true

  def email_subject
    "[PULFA] #{subject_string}"
  end

  def subject_string
    return title if subject == "collection"
    subject
  end

  def subject_options
    [
      ["This Collection", "collection"],
      ["Reproductions & Photocopies", "reproduction"],
      ["Rights & Permissions", "permission"],
      ["Access", "access"],
      ["Other", "how much"]
    ]
  end

  def submit
    ContactMailer.with(form: self).contact.deliver
    @submitted = true
    @name = ""
    @email = ""
    @message = ""
  end

  def submitted?
    @submitted == true
  end

  def routed_mail_to
    case location_code
    when "rbsc", "lae", "mss", "rarebooks"
      "rbsc@princeton.edu"
    when "mudd", "publicpolicy", "univarchives"
      "mudd@princeton.edu"
    when "engineering library", "eng"
      "wdressel@princeton.edu"
    when "ga"
      "jmellby@princeton.edu"
    end
  end
end
