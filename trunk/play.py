#!/usr/bin/env python
#

import wsgiref.handlers

from state import State

from google.appengine.api import users
from google.appengine.ext import db
from google.appengine.ext import webapp

class Grid(webapp.RequestHandler):
  def get(self):
    self.response.headers['Content-Type'] = 'text/plain'

    user = users.GetCurrentUser()
    if not user:
      self.response.out.write('g' + '_' * 72)
      return

    username = user.nickname()
    state = State.forUser(username)
    self.response.out.write(state.grid)

class Move(webapp.RequestHandler):
  def get(self):
    self.response.headers['Content-Type'] = 'text/plain'

    user = users.GetCurrentUser()
    if not user:
      self.response.out.write('NO_USER')
      return

    username = user.nickname()
    state = State.forUser(username)

    grid = self.request.get('grid')
    if not grid:
      self.response.out.write('NO_GRID')
      return
      
    if len(grid) != 73:
      self.response.out.write('BAD_GRID')
      return

    score = int(self.request.get('score'))
    if not score:
      self.response.out.write('NO_SCORE')
      return

    if score < 0 or score > 36:
      self.response.out.write('BAD_SCORE')
      return

    state.grid = grid
    state.score = score
    state.put()

    self.response.out.write('BINGO')

class Restart(webapp.RequestHandler):
  def get(self):
    self.response.headers['Content-Type'] = 'text/plain'

    user = users.GetCurrentUser()
    if not user:
      self.response.out.write('NO_USER')
      return

    username = user.nickname()
    state = State.newForUser(username)
    state.put()
    self.response.out.write(state.grid)


application = webapp.WSGIApplication([('/play/grid', Grid),
                                      ('/play/move', Move),
                                      ('/play/restart', Restart),],
                                     debug=True)

wsgiref.handlers.CGIHandler().run(application)
