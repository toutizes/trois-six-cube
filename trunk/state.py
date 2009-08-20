#!/usr/bin/env python
#
# Data for three-six-cube

import sys
import wsgiref.handlers

from datetime import datetime

from google.appengine.ext import db

class State(db.Model):
  username = db.StringProperty()   # Name of the user
  grid = db.StringProperty() # Color + height in row order.  Dot means unset.
  score = db.IntegerProperty()
  last_played = db.DateTimeProperty(auto_now=True)

  def forUser(username):
    query = State.gql("WHERE username = :1 ORDER BY last_played DESC", username)
    states = query.fetch(1)
    if len(states) == 1:
      return states[0]
    else:
      return State.newForUser(username)
  forUser = staticmethod(forUser)

  def newForUser(username):
    state = State()
    state.username = username
    state.grid = 'g' + ('_' * 72)
    state.score = 0
    state.last_played = default=datetime.now()
    state.put()
    return state
  newForUser = staticmethod(newForUser)

