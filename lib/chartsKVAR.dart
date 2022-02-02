// Local imports
import 'database.dart';
import 'panelsData.dart';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

// Contains the divisions for the y-axis
List<charts.TickSpec<num>> staticTicks = [];

class SeriesKVARBar extends StatelessWidget {

  // Contains the data to be display on chart
  final List<charts.Series<dynamic, DateTime>> seriesList;

  SeriesKVARBar(this.seriesList);

  factory SeriesKVARBar.withSampleData() {
    return new SeriesKVARBar(
      createData(),
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
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                "KVAR",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              Container(
                height: 895,
                child: new charts.TimeSeriesChart(
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
                  defaultRenderer: new charts.BarRendererConfig<DateTime>(),
                  defaultInteractions: false,
                  behaviors: [new charts.SelectNearest(), new charts.DomainHighlighter()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Class for KVAR bars
class SeriesKVAR {
  final DateTime time;
  final int value;

  SeriesKVAR(this.time, this.value);
}

// Returns the data to be displayed on the chart
List<charts.Series<SeriesKVAR, DateTime>> createData() {

    // List containing every bar
    List<SeriesKVAR> data = [];

    for (int i = 1; i < convertedData[int.parse(stringCurrentPanel[6]) - 1].length; i++) {
      // Current field containing date, time, steps, temperature and KVAR
      List<dynamic> currentRecord = convertedData[int.parse(stringCurrentPanel[6]) - 1][i];

      // Fetch from currentRecord the needed data
      String currentDate = currentRecord[0], currentTime = currentRecord[1], currentKVAR = currentRecord[14];

      List<dynamic> splitDate = currentDate.split('/');
      List<dynamic> splitTime = currentTime.split(':');

      // Add bar                                     Year                     Month                    Day                       Hour                    Minute                    KVAR Value
      data.add(new SeriesKVAR(new DateTime(int.parse(splitDate[2]), int.parse(splitDate[1]), int.parse(splitDate[0]), int.parse(splitTime[0]), int.parse(splitTime[1])), int.parse(currentKVAR)));
    }

    // Add a division every 50 on y-axis
    for (int i = 0; i <= 1000; i += 50) {
      staticTicks.add(new charts.TickSpec(i));
    }

    return [
      new charts.Series(
        id: 'KVAR',
        colorFn: (_, __) => charts.MaterialPalette.white,
        domainFn: (SeriesKVAR current, _) => current.time,
        measureFn: (SeriesKVAR current, _) => current.value,
        data: data,
      )
    ];
  }