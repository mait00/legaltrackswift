import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, StatusBar, View, Image, Animated, Easing, Alert } from 'react-native';
import { API, StorageHelper } from './../../services';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from './../../utilities/Common';

import { theme } from './../../../theme';

import { StackNavigationProp } from '@react-navigation/stack';
import { useNavigation } from '@react-navigation/native';

let spinValue = new Animated.Value(0);

const SplashScreen = ({getProfile, getTarifs, navigation, getNotifications, getCalendar}) => {
  const isMount = useRef<boolean>(false);

  useEffect(() => {
    Animated.loop(
      Animated.timing(
        spinValue,
        {
         toValue: 1,
         duration: 1000,
         easing: Easing.linear,
         useNativeDriver: true
        }
      )
    ).start();
    StorageHelper.getData('token')
    .then(token => {
      if (token && token.length) {
        API.setToken(token);
        getProfile()
        .then(profile => {
          navigation.navigate('LoginIn');
          getNotifications();
          getCalendar();
          getTarifs();
        })
        .catch(err => {
          navigation.navigate('Phone');
        });
      } else {
        navigation.navigate('Phone');
      }
    })
    .catch(err => {
      navigation.navigate('Phone');
    });
    // setTimeout(() => {
    //     navigation.navigate('Phone');
    // }, 3000);
  }, []);

  return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
            alignItems: 'center',
        }}>
          <Image source={require('./../../assets/splash.png')}
            style={{
              width: Common.getLengthByIPhone7(0),
              flex: 1,
              // height: Common.getLengthByIPhone7(16),
              resizeMode: 'cover',
            }}
          />
          <Animated.Image
            style={{
              width: Common.getLengthByIPhone7(65),
              height: Common.getLengthByIPhone7(65),
              position: 'absolute',
              bottom: Common.getLengthByIPhone7(180),
              transform: [{rotate: spinValue.interpolate({
                inputRange: [0, 1],
                outputRange: ['0deg', '360deg']
              })}] 
            }}
            source={require('./../../assets/ic-loader.png')}
          />
        </View>
  );
};

const mstp = (state: RootState) => ({
	isRequestGoing: state.user.isRequestGoing,
	userProfile: state.user.userProfile,
});

const mdtp = (dispatch: Dispatch) => ({
	getProfile: () => dispatch.user.getProfile(),
  getTarifs: () => dispatch.user.getTarifs(),
  getCalendar: () => dispatch.all.getCalendar(),
  getNotifications: () => dispatch.all.getNotifications(),
});

export default connect(mstp, mdtp)(SplashScreen);

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: theme.colors.backgroundColor,
  },
});
