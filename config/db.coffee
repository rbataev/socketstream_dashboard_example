# Place your Database config here

try
  global.mongoose = require 'mongoose'
catch e
  console.log "Error: Mongoose is missing. Please run 'npm install' in this directory to install it, then run MongoDB locally and retry"

mongoose.connect 'mongodb://localhost/dashboard'

global.Schema   = mongoose.Schema
global.ObjectId = Schema.ObjectId
