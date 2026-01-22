import React, { useEffect } from 'react';
import {View, Animated, Easing, TouchableOpacity, Image} from 'react-native';
import { colors } from '../styles';
import Common from './../utilities/Common';
import { RootState, Dispatch } from './../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Spinner from 'react-native-loading-spinner-overlay';

const LoadingView = ({endLoading, isRequestGoing}) => {
	
	let spinValue = new Animated.Value(0);

	return (
		<Spinner
          visible={endLoading}
          // textContent={'Загрузка...'}
          onShow={() => {
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
          }}
          onDismiss={() => {

          }}
          customIndicator={<View style={{
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 20000,
          }}>
            <View style={{
              width: Common.getLengthByIPhone7(65),
              height: Common.getLengthByIPhone7(65),
              alignItems: 'center',
              justifyContent: 'center',
            }}>
              <Animated.Image
                style={{
                  width: Common.getLengthByIPhone7(65),
                  height: Common.getLengthByIPhone7(65),
                  position: 'absolute',
                  bottom: 0,
                  left: 0,
                  transform: [{rotate: spinValue.interpolate({
                    inputRange: [0, 1],
                    outputRange: ['0deg', '360deg']
                  })}] 
                }}
                source={require('./../assets/ic-loader.png')}
              />
              <TouchableOpacity style={{
                // marginTop: Common.getLengthByIPhone7(20),
                padding: Common.getLengthByIPhone7(5),
                backgroundColor: 'rgba(255, 255, 255, 0.8)',
                borderRadius: Common.getLengthByIPhone7(5),
              }}
              onPress={() => {
                endLoading();
              }}>
                <Image
                  style={{
                    width: Common.getLengthByIPhone7(18),
                    height: Common.getLengthByIPhone7(18),
                  }}
                  source={require('./../assets/ic-loader-close.png')}
                />
              </TouchableOpacity>
            </View>
          </View>}
          overlayColor={'rgba(32, 42, 91, 0.3)'}
          textStyle={{color: '#FFF'}}
        />
	);
};

const mstp = (state: RootState) => ({
	isRequestGoing: state.user.isRequestGoing,
});

const mdtp = (dispatch: Dispatch) => ({
	endLoading: () => dispatch.user.endLoading(),
});

export default connect(mstp, mdtp)(LoadingView);