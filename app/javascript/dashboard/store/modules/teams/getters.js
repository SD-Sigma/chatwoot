export const getters = {
  getTeams($state) {
    return Object.values($state.records).sort((a, b) => a.id - b.id);
  },
  getTeamById: $state => id => {
    return (
      Object.values($state.records).find(record => record.id === Number(id)) ||
      {}
    );
  },
  getTeamsWithOnlineAgents: ($state, $getters, rootState, rootGetters) => {
    const teams = Object.values($state.records);

    return teams.filter(team => {
      const agents = rootGetters['teamMembers/getTeamMembers'](team.id) || [];
      return agents.some(agent => agent.availability_status === 'online');
    });
  },
  getMyTeams($state, $getters) {
    return $getters.getTeams.filter(team => {
      const { is_member: isMember } = team;
      return isMember;
    });
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getTeam: $state => id => {
    const team = $state.records[id];
    return team || {};
  },
};
