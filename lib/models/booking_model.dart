/// Bangladesh mobile financial services + standard card rails, plus a
/// "pay later" option that needs no payment integration at all. This list
/// mirrors what Bangladeshi travel/e-commerce apps typically offer.
enum PaymentMethod { bkash, nagad, rocket, card, payOnArrival }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.bkash:
        return 'bKash';
      case PaymentMethod.nagad:
        return 'Nagad';
      case PaymentMethod.rocket:
        return 'Rocket';
      case PaymentMethod.card:
        return 'Debit / Credit Card';
      case PaymentMethod.payOnArrival:
        return 'Pay on Arrival';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.bkash:
        return 'Pay instantly with your bKash account';
      case PaymentMethod.nagad:
        return 'Pay instantly with your Nagad account';
      case PaymentMethod.rocket:
        return 'Pay instantly with your Rocket account';
      case PaymentMethod.card:
        return 'Visa, Mastercard, or local bank cards';
      case PaymentMethod.payOnArrival:
        return 'Reserve now, pay in cash or card at check-in';
    }
  }
}

enum PaymentStatus { pending, processing, success, failed, payLater }

enum BookingType { hotel, transport }

/// A single booking — a hotel stay or a transport ticket — created from
/// the Trip Planner, Hotel detail screen, or Transportation module.
class Booking {
  final String id;
  final BookingType type;
  final String itemId; // hotelId or transport route id
  final String itemName;
  final String itemImageUrl;
  final DateTime travelDate;
  final int travelers;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? transactionId;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.itemImageUrl,
    required this.travelDate,
    required this.travelers,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    required this.createdAt,
  });

  Booking copyWith({PaymentStatus? paymentStatus, String? transactionId}) {
    return Booking(
      id: id,
      type: type,
      itemId: itemId,
      itemName: itemName,
      itemImageUrl: itemImageUrl,
      travelDate: travelDate,
      travelers: travelers,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'itemId': itemId,
        'itemName': itemName,
        'itemImageUrl': itemImageUrl,
        'travelDate': travelDate.toIso8601String(),
        'travelers': travelers,
        'amount': amount,
        'paymentMethod': paymentMethod.name,
        'paymentStatus': paymentStatus.name,
        'transactionId': transactionId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      type: BookingType.values.firstWhere((e) => e.name == json['type'], orElse: () => BookingType.hotel),
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      itemImageUrl: json['itemImageUrl'] as String? ?? '',
      travelDate: DateTime.parse(json['travelDate'] as String),
      travelers: json['travelers'] as int,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere((e) => e.name == json['paymentMethod'], orElse: () => PaymentMethod.payOnArrival),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == json['paymentStatus'], orElse: () => PaymentStatus.payLater),
      transactionId: json['transactionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
