
import 'dart:ui';

class DeviceDetail {
  final String name;
  final String deviceId;
  final String status;
  final int unread;
  final int signalStrength;
  final String distance;
  final String avatar;
  final Color color;
  
  DeviceDetail({
    required this.name,
    required this.deviceId,
    required this.status,
    required this.unread,
    required this.signalStrength,
    required this.distance,
    required this.avatar,
    required this.color,
  });

//to deal with individual device updates
  DeviceDetail copyWith({int? unread}) {
    return DeviceDetail(
      name: name,
      deviceId: deviceId,
      status: status,
      unread: unread ?? this.unread,
      signalStrength: signalStrength,
      distance: distance,
      avatar: avatar,
      color: color,
    );
  }
  //so in the screen 
  //-> final connected = devices
        //.where((d) => d.status == 'Active')
        // .length;
}