class IndianEmergencyNumbers {
  // National Numbers
  static const String ambulance = '108';
  static const String police = '100';
  static const String fire = '101';
  static const String unified = '112';
  static const String highway = '1033';
  static const String womenHelpline = '1091';
  static const String childHelpline = '1098';

  // State-wise ambulance numbers
  static const Map<String, Map<String, String>> stateNumbers = {
    'Andhra Pradesh': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Arunachal Pradesh': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Assam': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Bihar': {
      'ambulance': '102',
      'police': '100',
      'highway': '1033',
    },
    'Chhattisgarh': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Goa': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Gujarat': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Haryana': {
      'ambulance': '102',
      'police': '100',
      'highway': '1033',
    },
    'Himachal Pradesh': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Jharkhand': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Karnataka': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Kerala': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Madhya Pradesh': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Maharashtra': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Manipur': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Meghalaya': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Mizoram': {
      'ambulance': '102',
      'police': '100',
      'highway': '1033',
    },
    'Nagaland': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Odisha': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Punjab': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Rajasthan': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Sikkim': {
      'ambulance': '102',
      'police': '100',
      'highway': '1033',
    },
    'Tamil Nadu': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
      'coastalPatrol': '1093',
    },
    'Telangana': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Tripura': {
      'ambulance': '102',
      'police': '100',
      'highway': '1033',
    },
    'Uttar Pradesh': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'Uttarakhand': {
      'ambulance': '108',
      'police': '100',
      'highway': '1033',
    },
    'West Bengal': {
      'ambulance': '102',
      'police': '100',
      'highway': '1033',
    },
    // Union Territories
    'Delhi': {
      'ambulance': '102',
      'police': '100',
      'highway': '1033',
    },
  };

  static Map<String, String> getNumbersForState(String state) {
    return stateNumbers[state] ??
        {
          'ambulance': ambulance,
          'police': police,
          'highway': highway,
        };
  }
}
