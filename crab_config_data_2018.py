from CRABClient.UserUtilities import config
config = config()

config.General.requestName = 'DATASET_DATE_2018'
config.General.workArea = 'crab_projects'
config.General.transferOutputs = True
config.General.transferLogs = True

config.JobType.numCores = 1
config.JobType.maxMemoryMB = 2500
config.JobType.pluginName = 'Analysis'
config.JobType.psetName = 'ntuple_mc_2018_forData_cfg.py'

#config.Data.inputDataset = 'root://cmsxrootd.fnal.gov//store/data/Run2018A/EGamma/USER/EXOMONOPOLE-12Nov2019_UL2018-v2/270007/7F10EF9D-BDF9-074B-8216-834602DE11C3.root' # aqui se coloca todo o dataset se quiser rodar para tudo
config.Data.userInputFiles = ['root://cmsxrootd.fnal.gov//store/data/Run2018A/EGamma/USER/EXOMONOPOLE-12Nov2019_UL2018-v2/270007/7F10EF9D-BDF9-074B-8216-834602DE11C3.root']
config.Data.inputDBS = 'global'
config.Data.splitting = 'FileBased'
config.Data.unitsPerJob = 1
config.Data.totalUnits = -1
config.Data.outLFNDirBase = 'gsiftp://eosuserftp.cern.ch/eos/user/m/matheus/magnetic_monopole_Data2018' #%s/' % (getUsernameFromSiteDB())
config.Data.publication = False

config.Site.storageSite = 'T3_CH_CERNBOX'  # Para salvar no CERN BOX

