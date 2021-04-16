import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_draw_route/directions_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'directions_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Demo",
      theme: ThemeData(primaryColor: Colors.white),
      home: _MapScreen(),
    );
  }
}

class _MapScreen extends StatefulWidget {
  @override
  __MapScreenState createState() => __MapScreenState();
}

class __MapScreenState extends State<_MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(41.017901, 28.847953),
    zoom: 16.5, //genellikle max 21 kullanilir.
  );

  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  // uzun basarsa mapte origin isaretleniyor diger uzun basista hedef.

  GoogleMapController _googleMapController;
  Marker _origin;
  Marker _destination;
  Directions _info;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text("Google Maps"),
        actions: [
          if (_origin != null)
            TextButton(
              onPressed: () => _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _origin.position,
                    zoom: 14.5,
                    tilt: 50.0,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.green,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text("ORIGIN"),
            ),
          if (_destination != null)
            TextButton(
              onPressed: () => _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _destination.position,
                    zoom: 14.5,
                    tilt: 50.0,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text("DESTINATION"),
            ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(

            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _googleMapController = controller,
            markers: {
              if (_origin != null) _origin,
              if (_destination != null) _destination,
            },
            polylines: {
              if (_info != null)
                Polyline(
                    polylineId: const PolylineId('overview_polyline'),
                    color: Colors.blueGrey,
                    width: 5,
                    points: _info.polylinePoints
                        .map((e) => LatLng(e.latitude, e.longitude))
                        .toList())
            },
            onLongPress: _addMarker,
          ),
          if (_info != null)
            Positioned(
              top: 20.0,
              child: Container(
                height: 45.0,
                width: MediaQuery.of(context).size.width / 1.5,
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6.0,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    '${_info.totalDistance}, ${_info.totalDuration}',
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        onPressed: () => _googleMapController.animateCamera(_info != null
            ? CameraUpdate.newLatLngBounds(_info.bounds, 100.0)
            : CameraUpdate.newCameraPosition(_initialCameraPosition)),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  void _addMarker(LatLng pos) async {
    if (_origin == null || (_origin != null && _destination != null)) {
      setState(() {
        _origin = Marker(
            markerId: const MarkerId('origin'),
            infoWindow: const InfoWindow(title: 'Origin'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            position: pos);
        _destination = null;

        _info = null;
      });
    } else {
      //origin is already set
      //Set destination
      setState(() {
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          position: pos,
        );
      });
      //get directions
      final directions = await DirectionsRepository()
          .getDirections(origin: _origin.position, destination: pos);
      setState(() {
        _info = directions;

      });
    }
  }
}
