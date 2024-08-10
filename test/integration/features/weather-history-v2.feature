Feature:
  As an API Developer
  I want to get historical weather data
  So that I can independently build a weather application

  Scenario: Get stations near dfw
    Given I set apikey header to `apikey`
    When I GET /v2/weather-history/stations?near=dfw
    Then response code should be 200
    And response body should be valid json
    And response body should contain GRAPEVINE

  Scenario: Get temperature data for ASN00086038 station in 2018
    Given I set apikey header to `apikey`
    When I GET /v2/weather-history/stations/ASN00086038/years/2018/temp
    Then response code should be 200
    And response body should be valid json
    And response body should contain 2018-01-04
    And response body should contain 12.4

  Scenario: Get wind data for USW00003927 station in 2022
    Given I set apikey header to `apikey`
    When I GET /v2/weather-history/stations/USW00003927/years/2022/wind
    Then response code should be 200
    And response body should be valid json
    And response body should contain 2022-01-07
    And response body should contain 7.0

  Scenario: Request fails with no api key present
    When I GET /v2/weather-history/stations/ASN00086038/years/2018/temp
    Then response code should be 401

  Scenario: Request does not fail when OPTIONS is requested
    Given I set origin header to apickli
    And I set Access-Control-Request-Method header to GET
    When I request OPTIONS for /v2/weather-history/stations/ASN00086038/years/2018/temp
    Then response code should be 200
    And response header Access-Control-Allow-Origin should exist

  Scenario: Get stations near perth
    Given I set apikey header to `apikey`
    When I GET /v2/weather-history/stations?near=perth
    Then response code should be 200
    And response body should be valid json

  Scenario: Get temperature data for ASN00009225 station in 2019
    Given I set apikey header to `apikey`
    When I GET /v2/weather-history/stations/ASN00009225/years/2019/temp
    Then response code should be 200
    And response body should be valid json