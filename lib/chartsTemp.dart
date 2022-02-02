// Local imports
import 'database.dart';
import 'panelsData.dart';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

// Contains the divisions for the y-axis
List<charts.TickSpec<num>> staticTicks = [];

class SeriesTempBar extends StatelessWidget {

  // Contains the data to be display on chart
  final List<charts.Series<dynamic, DateTime>> seriesList;

  SeriesTempBar(this.seriesList);

  factory SeriesTempBar.withSampleData() {
    return new SeriesTempBar(
      createTempData()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1000,
      padding: EdgeInsets.all(20),
      child: Card(
        color: Colors.teal[300],
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                "Temperature",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              Container(
                height: 895,
                child: charts.TimeSeriesChart(
                  seriesList,
                  animate: true, 
                  domainAxis: new charts.DateTimeAxisSpec(
                    renderSpec: new charts.SmallTickRendererSpec(
                      labelStyle: new charts.TextStyleSpec(
                        fontSize: 18,
                        color: charts.MaterialPalette.white),
                    )
                  ),
                  primaryMeasureAxis: new charts.NumericAxisSpec(
                    showAxisLine: true,
                    // Providing custom divisons on y-axis
                    tickProviderSpec: charts.StaticNumericTickProviderSpec(
                      staticTicks,
                    ),
                    renderSpec: new charts.GridlineRendererSpec(  
                      labelStyle: new charts.TextStyleSpec(
                        fontSize: 18, 
                        color: charts.MaterialPalette.white),
                    )
                  ),
                  defaultInteractions: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Class for temperature points
class SeriesTemp {
  final DateTime time;
  final double value;

  SeriesTemp(this.time, this.value);
}

// Returns the data to be displayed on the chart
List<charts.Series<SeriesTemp, DateTime>> createTempData() {

    // List containing every point
    List<SeriesTemp> data = [];

    for (int i = 1; i < convertedData[int.parse(stringCurrentPanel[6]) - 1].length; i++) {
      // Current field containing date, time, steps, temperature and KVAR
      List<dynamic> currentRecord = (roomTemperature ? roomTempData[i] : convertedData[int.parse(stringCurrentPanel[6]) - 1][i]);

      // Fetch from currentRecord the needed data
      String currentDate = currentRecord[0], currentTime = currentRecord[1], currentTemp = currentRecord[(roomTemperature ? 2 : 15)];

      List<dynamic> splitDate = currentDate.split('/');
      List<dynamic> splitTime = currentTime.split(':');

      // Add bar                                     Year                     Month                    Day                       Hour                    Minute                    Temperature Value
      data.add(new SeriesTemp(new DateTime(int.parse(splitDate[2]), int.parse(splitDate[1]), int.parse(splitDate[0]), int.parse(splitTime[0]), int.parse(splitTime[1])), double.parse(currentTemp)));
    }

    // Add a division every 5 on y-axis
    for (int i = 0; i <= 100; i += 5) {
      staticTicks.add(new charts.TickSpec(i));
    }

    return [
      new charts.Series<SeriesTemp, DateTime>(
        id: 'Temperature',
        colorFn: (_, __) => charts.MaterialPalette.deepOrange.shadeDefault,
        domainFn: (SeriesTemp current, _) => current.time,
        measureFn: (SeriesTemp current, _) => current.value,
        data: data,
      )
    ];
  }