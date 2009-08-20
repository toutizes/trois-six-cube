#!/usr/bin/env python
#
# Main handler.
# Redirects to login page if needed.
# Otherwise expands the template for the selected page.

import os
import sys
import wsgiref.handlers

from state import State

from google.appengine.ext import db
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import login_required
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext.webapp import template
from google.appengine.api import users

class CommonPage(webapp.RequestHandler):
  def CommonValues(self):
    return {
      'login_url': users.create_logout_url(self.request.uri),
      'login_url_linktext': 'Pas moi',
      'user_name': users.get_current_user().nickname(),
    }

  @login_required
  def get(self):
    values = self.Values()
    path = os.path.join(os.path.dirname(__file__), self.page)
    self.response.headers['Content-Type'] = 'text/html'
    self.response.out.write(template.render(path, values))

  # Subclasses can override this
  def Values(self):
    return self.CommonValues()

class CreditsPage(CommonPage):
  page = 'pages/credits.html'
    
class GamePage(CommonPage):
  page = 'pages/game.html'

class Status(object):
  def __init__(self, full_name, score, style):
    at_index = full_name.find('@')
    if at_index == -1:
      self.name = full_name
    else:
      self.name = full_name[0 : at_index]
    self.score = score
    self.style = style

class ScorePage(CommonPage):
  page = 'pages/score.html'
  def Values(self):
    values = self.CommonValues()
    states = State.gql("ORDER BY last_played DESC")
    statuses = []
    style = "oddrow"
    for state in states.fetch(17):
      statuses.append(Status(state.username, state.score, style))
      if style == "oddrow":
        style = "evenrow"
      else:
        style = "oddrow"
    values['statuses'] = statuses
    return values
    
class TestPage(webapp.RequestHandler):
  def get(self):
    self.response.headers['Content-Type'] = 'text/html'
    self.response.out.write('hello')

application = \
  webapp.WSGIApplication([('/game', GamePage),
                          ('/score', ScorePage),
                          ('/', GamePage)],
                         debug=False)

def main():
  run_wsgi_app(application)

if __name__ == "__main__":
  main()
