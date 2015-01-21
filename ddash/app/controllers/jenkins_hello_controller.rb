# For data that shows up in the initial Jenkins Hello screen
class JenkinsHelloController < ApplicationController
  require 'resque'
  require 'googlecharts'
  require_dependency 'jenkins_jobs_objects'
  def index
    # jobs by master
    @masters_counts     = []
    @masters_aborted    = []
    @masters_red        = []
    @masters_blue       = []
    Ddash::Application.config.JENKINS_MASTERS.each do |master|
      @masters_counts.push(JenkinsHello.by_master(master).count)
      @masters_aborted.push(JenkinsHello.by_master(master).by_color_aborted.count)
      @masters_red.push(JenkinsHello.by_master(master).by_color_red.count)
      @masters_blue.push(JenkinsHello.by_master(master).by_color_blue.count)
    end
    #### charts
    # Total Jobs by status
    @total_job_status_pie_chart = Gchart.pie_3d(
      data: [
        JenkinsHello::red_jobs.count,
        JenkinsHello::blue_jobs.count,
        JenkinsHello::yellow_jobs.count,
        JenkinsHello::grey_jobs.count,
        JenkinsHello::disabled_jobs.count,
        JenkinsHello::notbuilt_jobs.count,
        JenkinsHello::aborted_jobs.count],
      title: 'Total job status',
      size: '600x300',
      labels: [
        'red',
        'blue',
        'yellow',
        'grey',
        'disabled',
        'not built',
        'aborted'])
    # Jobs by Jenkins Master
    @jobs_by_jenkins_master_chart = Gchart.pie(
      data: @masters_counts,
      title: 'Jobs by Jenkins Master',
      size: '600x300',
      labels:     JenkinsHello::masters_names)
    # Failed Jobs by Jenkins Master
    @aborted_jobs_by_jenkins_master_chart = Gchart.pie(
      data: @masters_aborted,
      title: 'Aborted Jobs by Jenkins Master',
      size: '600x300',
      labels:     JenkinsHello::masters_names)
    # red Jobs by Jenkins Master
    @red_jobs_by_jenkins_master_chart = Gchart.pie(
      data: @masters_red,
      title: 'Red Jobs by Jenkins Master',
      size: '600x300',
      labels:     JenkinsHello::masters_names)
    # blue Jobs by Jenkins Master
    @blue_jobs_by_jenkins_master_chart = Gchart.pie(
      data: @masters_blue,
      title: 'Blue Jobs by Jenkins Master',
      size: '600x300',
      labels:     JenkinsHello::masters_names)
  end

  def create
    @all_status       = []
    kaboose           = 'api/json'
    gen_objects       = JenkinsJobsObjects.new
    Ddash::Application.config.JENKINS_MASTERS.each do |jenkins_master|
      gen_objects.jenkins_params = [
        "http://#{jenkins_master}/",
        "#{kaboose}"
      ]
      jobs_objects                    = gen_objects.gather
      # save to DB
      jobs_objects.each do |jo|
        jo[:master] = "#{jenkins_master}"
        @this_hello = JenkinsHello.new(jo)
        @this_hello.save
      end
    end
  end
end # end class
