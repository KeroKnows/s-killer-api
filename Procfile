web: bundle exec puma -t 5:5 -p ${PORT:-4001} -e ${RACK_ENV:-production}
worker: bundle exec shoryuken -r ./workers/skill_extractor_worker.rb -q ${EXTRACTOR_QUEUE_URL}