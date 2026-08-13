import 'dart:async';

import 'package:flutter/material.dart';

class ChatedUser {
  ChatedUser({
    this.propertyId,
    this.title,
    this.translatedTitle,
    this.titleImage,
    this.userId,
    this.unreadCount,
    this.name,
    this.profile,
    this.firebaseId,
    this.fcmId,
    this.isBlockedByMe,
    this.isBlockedByUser,
    this.isAgent,
    this.isAgentVerified,
    this.isUserVerified,
    this.isAdmin,
  });

  ChatedUser.fromJson(Map<String, dynamic> json, {BuildContext? context}) {
    final profileImage =
        json['profile'] ??
        json['user_profile'] ??
        json['profile_image'] ??
        json['image'];
    if (context != null && profileImage != null && profileImage != '') {
      unawaited(
        precacheImage(NetworkImage(profileImage.toString()), context),
      );
    }
    if (context != null &&
        json['title_image'] != null &&
        json['title_image'] != '') {
      unawaited(
        precacheImage(
          NetworkImage(json['title_image']?.toString() ?? ''),
          context,
        ),
      );
    }
    propertyId = json['property_id'] as int?;
    userId = json['user_id'] as int?;
    title = json['title']?.toString() ?? '';
    translatedTitle = json['translated_title']?.toString() ?? '';
    titleImage = json['title_image']?.toString() ?? '';
    unreadCount = json['unread_count']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
    profile = profileImage?.toString() ?? '';
    firebaseId = json['firebase_id']?.toString() ?? '';
    fcmId = json['fcm_id']?.toString() ?? '';
    isBlockedByMe = _asBool(json['is_blocked_by_me']);
    isBlockedByUser = _asBool(json['is_blocked_by_user']);
    isAgent = _asBool(json['is_agent']);
    isAgentVerified = _asBool(json['is_agent_verified']);
    isUserVerified = _asBool(json['is_user_verified']);
    isAdmin = _asBool(json['is_admin']);
  }
  int? propertyId;
  int? userId;
  String? title;
  String? translatedTitle;
  String? titleImage;

  String? name;
  String? unreadCount;
  String? profile;
  String? firebaseId;
  String? fcmId;
  bool? isBlockedByMe;
  bool? isBlockedByUser;
  bool? isAgent;
  bool? isAgentVerified;
  bool? isUserVerified;
  bool? isAdmin;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['property_id'] = propertyId;
    data['title'] = title;
    data['translated_title'] = translatedTitle;
    data['title_image'] = titleImage;
    data['user_id'] = userId;
    data['unread_count'] = unreadCount;
    data['name'] = name;
    data['profile'] = profile;
    data['firebase_id'] = firebaseId;
    data['fcm_id'] = fcmId;
    data['is_blocked_by_me'] = isBlockedByMe;
    data['is_blocked_by_user'] = isBlockedByUser;
    data['is_agent'] = isAgent;
    data['is_agent_verified'] = isAgentVerified;
    data['is_user_verified'] = isUserVerified;
    data['is_admin'] = isAdmin;
    return data;
  }
}

bool _asBool(dynamic value) {
  final normalized = value?.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}
