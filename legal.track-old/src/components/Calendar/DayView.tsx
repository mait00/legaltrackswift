import React, { useEffect } from 'react';
import {StyleSheet, Image, View, Text, TouchableOpacity} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';

const DayView = ({data, action}) => {

	const getTime = time => {
		let date = new Date(time);
		let hh = date.getHours();
		hh = hh < 10 ? '0' + hh : hh;

		let mm = date.getMinutes();
		mm = mm < 10 ? '0' + mm : mm;

		return hh + ':' + mm;
	}

    return (
		<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			// height: Common.getLengthByIPhone7(44),
			borderRadius: Common.getLengthByIPhone7(12),
			marginBottom: Common.getLengthByIPhone7(12),
			// flexDirection: 'row',
			alignItems: 'flex-start',
			justifyContent: 'space-between',
			backgroundColor: 'white',
			shadowColor: "#000",
			shadowOffset: {
				width: 0,
				height: 2,
			},
			shadowOpacity: 0.08,
			shadowRadius: 7.00,
			elevation: 1,
		}}
		onPress={() => {
			if (action) {
				action();
			}
		}}>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				height: Common.getLengthByIPhone7(36),
				backgroundColor: '#EAE9EF',
				borderTopLeftRadius: Common.getLengthByIPhone7(12),
				borderTopRightRadius: Common.getLengthByIPhone7(12),
				paddingLeft: Common.getLengthByIPhone7(10),
				paddingRight: Common.getLengthByIPhone7(10),
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'flex-start',
			}}>
				<Image source={require('./../../assets/ic-clock.png')}
					style={{
						width: Common.getLengthByIPhone7(24),
						height: Common.getLengthByIPhone7(24),
						resizeMode: 'contain',
					}}
				/>
				<Text style={{
					marginLeft: 2,
					color: colors.MAIN_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(16),
				}}
				allowFontScaling={false}>
					{getTime(data.start)}
				</Text>
			</View>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				backgroundColor: 'white',
				borderBottomLeftRadius: Common.getLengthByIPhone7(12),
				borderBottomRightRadius: Common.getLengthByIPhone7(12),
				paddingLeft: Common.getLengthByIPhone7(16),
				paddingRight: Common.getLengthByIPhone7(16),
				paddingTop: Common.getLengthByIPhone7(10),
				paddingBottom: Common.getLengthByIPhone7(12),
			}}>
				<Text style={{
					marginBottom: 3,
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(16),
				}}
				allowFontScaling={false}>
					{data.head}
				</Text>
				<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(14),
				}}
				allowFontScaling={false}>
					{data.second}
				</Text>
			</View>
		</TouchableOpacity>
	);
};

export default DayView;