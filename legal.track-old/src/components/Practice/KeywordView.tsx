import React, { useEffect } from 'react';
import {StyleSheet, Image, View, Text, TouchableOpacity} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';

const KeywordView = ({data, action, index, onShowMenu}) => {

    return (
		<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			marginTop: index === 0 ? Common.getLengthByIPhone7(10) : 0,
			borderRadius: Common.getLengthByIPhone7(12),
			marginBottom: Common.getLengthByIPhone7(10),
			paddingLeft: Common.getLengthByIPhone7(15),
			paddingRight: Common.getLengthByIPhone7(15),
			paddingTop: Common.getLengthByIPhone7(8),
			paddingBottom: Common.getLengthByIPhone7(10),
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
			action();
		}}>
			<Text style={{
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'bold',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(14),
				lineHeight: Common.getLengthByIPhone7(17),
			}}
			allowFontScaling={false}>
				{data.value}
			</Text>
			<View style={{
				marginTop: 1,
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(70),
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'space-between',
			}}>
				<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(10),
					lineHeight: Common.getLengthByIPhone7(12),
				}}
				allowFontScaling={false}>
					Судебных актов за неделю: {data.total_cases}
				</Text>
				<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(10),
					lineHeight: Common.getLengthByIPhone7(12),
				}}
				allowFontScaling={false}>
					{data.last_event}
				</Text>
			</View>
		</TouchableOpacity>
	);
};

export default KeywordView;