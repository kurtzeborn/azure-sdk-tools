import os
import sys

from github import Github, GithubException

#
# Help
#


def print_help():
    print("""
Usage: gh_teams.py [command] [options]

Commands:
    list [org] [team] - lists all members of a team and recursively members of sub teams

Notes:
    Expects environment variable GH_TOKEN to be filled with your 
    access token to GitHub.  This can be generated on GitHub under
    Account->Settings->Developer settings->Personal access tokens.
    """)
    sys.exit()

#
# List
#

def list(org_name, team_name):
    con = Github(os.environ["GH_TOKEN"])
    org = con.get_organization(org_name)
    try:
        # try the slug lookup first (much faster)
        team = org.get_team_by_slug(team_name)
    except:
        team = None

    if team is None:
        # try the name lookup through all org teams
        teams = org.get_teams()
        for t in teams:
            if t.name == team_name:
                team = t

    if team is None:
        # give up
        print (f"Team {team_name} not found in {org_name}")
        return
    
    print(f"{team.members_count} members in {org_name}/{team_name}:")
    for member in team.get_members():
        print(member.login)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print_help()

    if sys.argv[1] == "list" and len(sys.argv) == 4:
        list(sys.argv[2], sys.argv[3])
 #   elif sys.argv[1] == "command" and len(sys.argv) == 3:
 #       command(sys.argv[2])
    else:
        print_help()
