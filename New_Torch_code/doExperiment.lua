require 'custom'

function doExperiment(trdata_type, testdata_type, mlp_architecture, feature_ex_type, conv_architecture,
                      conv_kernel, conv_pool, mwindow, db_seed, net_init_seed, batchsize,
                      lr, lr_decay, momentum, dropout_rate)
  -- Optional values
  conv_architecture = conv_architecture or {75, 75, 75}
  conv_kernel = conv_kernel or 50
  conv_pool = conv_pool or 2
  mwindow = mwindow or 50
  db_seed = db_seed or 1
  net_init_seed = net_init_seed or 1
  batchsize = batchsize or 30
  lr = lr or 1e-3
  lr_decay = lr_decay or 1e-5
  momentum = momentum or 0
  dropout_rate = dropout_rate or 0.5

  -- Experiment option
  print '==> Processing options'
  cmd = torch.CmdLine()
  cmd:text()
  cmd:text('Reducing False Alarms in ICU')
  cmd:text()
  cmd:text('Options:')
  -- Learning data
  cmd:option('-trdata_type', trdata_type)
  cmd:option('-testdata_type', testdata_type)
  -- Model
  cmd:option('-inputSize', 2500) -- 250Hz * 10sec
  cmd:option('-nInputFeature', 1)
  cmd:option('-nTarget', 2)
  ---- For MLP
  cmd:option('-mlp_architecture', mlp_architecture)
  cmd:option('-mlp_string', arch2string(mlp_architecture))
  ---- Feature extraction type
  cmd:option('-feature_ex_type', feature_ex_type)
  if feature_ex_type == 'conv' then -- For convolutional networks
    cmd:option('-conv_architecture', conv_architecture)
    cmd:option('-conv_kernel', conv_kernel)
    cmd:option('-conv_pool', conv_pool)
  elseif feature_ex_type == 'max' or feature_ex_type == 'min' or feature_ex_type == 'max-min' or feature_ex_type == 'mmpool' then -- For Max-Min layers
    cmd:option('-mwindow', mwindow)
  elseif feature_ex_type == 'mmconv' then
    cmd:option('-conv_architecture', conv_architecture)
    cmd:option('-conv_kernel', conv_kernel)
    cmd:option('-conv_pool', conv_pool)
    cmd:option('-mwindow', mwindow)
  else
    print("Something Wrong!!!!!!!!!!!!!")
  end
  ---- Experiment Setting
  -- cmd:option('-max_upIter', 42000) -- Update iteration, Not epoch
  cmd:option('-max_iter', 200)
  cmd:option('-db_seed', db_seed)
  cmd:option('-net_init_seed', net_init_seed)
  cmd:option('-batchsize', batchsize)
  cmd:option('-lr', lr)
  cmd:option('-lr_decay', lr_decay)
  cmd:option('-momentum', momentum)
  cmd:option('-dropout_rate', dropout_rate)
  cmd:text()

  option = cmd:parse(arg or {})

  foldername = '/home/heehwan/Workspace/Data/ReduceFA_2015/revised_output/1105/'
  filename = arch2string(mlp_architecture) .. '-' .. feature_ex_type
  option.rundir = cmd:string(foldername, option, {dir=true})
  cmd:log(option.rundir .. filename .. '-log', option)
  ----------------------------------------------------------------------
  print('\n')
  require 'getLearningData'
  nTraining, trainset_input, trainset_target, nTesting, testset_input, testset_target = getLearningData(option)

  print(trainset_input:size())
  print(testset_input:size())
  ----------------------------------------------------------------------
  require 'buildModel'
  model = buildModel(option)
  ----------------------------------------------------------------------
  require 'configureSetting'
  configureSetting(option)
  ----------------------------------------------------------------------
  train_accu = torch.zeros(max_iter, 1)
  train_err = torch.zeros(max_iter, 1)

  test_accu = torch.zeros(max_iter, 1)
  test_err = torch.zeros(max_iter, 1)
  test_conf = torch.zeros(max_iter, 4)

  require 'training'
  require 'test'

  print('==> Start training')
  print('==> # of max iteration: ' .. max_iter)
  iter = 1
  -- upiter = 1
  while iter <= max_iter do
    training()
    test()

    iter = iter + 1
  end
  ----------------------------------------------------------------------
  test_result:write('/pred_list', pred_list)
  test_result:write('/target_list', target_list)
  test_result:close()
  ----------------------------------------------------------------------
  recordfile = hdf5.open(foldername .. filename .. '.h5', 'w')
  recordfile:write('/train_accu', train_accu)
  recordfile:write('/train_err', train_err)
  recordfile:write('/test_accu', test_accu)
  recordfile:write('/test_err', test_err)
  recordfile:write('/test_confmatrix', test_conf)
  recordfile:close()
end
