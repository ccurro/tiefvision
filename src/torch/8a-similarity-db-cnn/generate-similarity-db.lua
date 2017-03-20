-- Copyright (C) 2016 Pau Carré Cardona - All Rights Reserved
-- You may use, distribute and modify this code under the
-- terms of the Apache License v2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt).

local paths = require('paths')
local torchFolder = paths.thisfile('..')
package.path = string.format("%s;%s/?.lua", os.getenv("LUA_PATH"), torchFolder)

require 'inn'
require 'optim'
require 'xlua'
require 'lfs'
require 'image'
local torch = require 'torch'

local tiefvision_commons = require '0-tiefvision-commons/tiefvision_commons'
local similarity_db_lib = require '8-similarity-db-cnn/similarity_db_lib'
local tiefvision_config_loader = require('0-tiefvision-commons/tiefvision_config_loader')

local function appendTensorToFile(f, x)
   -- only handles rank 1 tensors
   tbl = torch.totoable(x:squeeze())
   a = {}
   for k, v in pairs(tbl) do
      table.insert(a, tostring(v))
   end
   str = table.concat(a, ',')

   f.write(str .. "\n")
end

local function createDb(sourceFolder, destinationFolder)
  local files = tiefvision_commons.getFiles(sourceFolder)
  local encoder = similarity_db_lib.getEncoder()
  f = io.open('test.csv')  
  for fileIndex = 1, #files do
    local file = files[fileIndex]
    local destPath = destinationFolder .. '/' .. file

    paths.mkdir(destinationFolder)
    if(not tiefvision_commons.fileExists(destPath)) then
      print('Encoding ' .. file)
      local encoderOutput = similarity_db_lib.encodeImage(sourceFolder .. '/' .. file, encoder)
      torch.save(destPath, encoderOutput)
      -- add spot to write ascii *line* to file
      appendTensorToFile(f, encoderOutput)
      collectgarbage()
    end
  end
  f:close
end

function getOptions()
  local function extract_table(value)
    local tmp = {}
    for w in string.gmatch(value, "[^ ]+") do table.insert(tmp, w) end

    return tmp
  end

  local cmd = torch.CmdLine()
  local sources = tiefvision_commons.resourcePath('dresses-db/bboxes/1') .. ' ' .. tiefvision_commons.resourcePath('dresses-db/bboxes-flipped/1')
  cmd:option('-sources', sources, 'Source directory to load images')

  local destinations = tiefvision_commons.dataPath('encoded-images') .. ' ' .. tiefvision_commons.dataPath('encoded-images-flipped')
  cmd:option('-destinations', destinations, 'Source directory to load images')

  cmd:text('')
  cmd:option('-config', tiefvision_config_loader.default, 'Configuration file to use.')

  local args = cmd:parse(arg)
  args.sources = extract_table(args.sources)
  args.destinations = extract_table(args.destinations)

  assert(#args.sources == #args.destinations)

  return args
end

local options = getOptions()
for i = 1, #options.sources do
  createDb(options.sources[i], options.destinations[i])
end
