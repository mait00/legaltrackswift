import React, { useEffect } from 'react';
import {StyleSheet, Platform, TextInput, View, Text, TouchableOpacity} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';

const ButtonView = ({buttonIndex, setButtonIndex}) => {

	// useEffect(() => {
	// 	if (search.length) {
	// 		let newArray = pointsRaw.filter(el => {
	// 			return el.name.toLowerCase().indexOf(search.toLowerCase()) !== -1;
	// 		});
	// 		setPoints({points: newArray});
	// 	} else {
	// 		setPoints({points: pointsRaw});
	// 	}
	// }, [search])

	const renderButton = (title: string, key: number) => {
		return (<TouchableOpacity style={{
			height: Common.getLengthByIPhone7(36),
			width: (Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(48))/4,
			borderRadius: Common.getLengthByIPhone7(10),
			// paddingLeft: Common.getLengthByIPhone7(34),
			// paddingRight: Common.getLengthByIPhone7(34),
			backgroundColor: key === buttonIndex ? colors.MAIN_COLOR : 'transparent',
			alignItems: 'center',
			justifyContent: 'center',
		}}
		activeOpacity={1}
		onPress={() => {
			setButtonIndex(key);
		}}>
			<Text style={{
				color: key === buttonIndex ? 'white' : colors.MAIN_COLOR,
				fontFamily: key === buttonIndex ? 'Montserrat-Regular' : 'SFProDisplay-Regular',
				fontWeight: key === buttonIndex ? (Platform.OS === 'ios' ? '600' : 'bold') : 'normal',
				textAlign: 'left',
				fontSize: key === buttonIndex ? Common.getLengthByIPhone7(12) : Common.getLengthByIPhone7(13),
			}}
			allowFontScaling={false}>
				{title}
			</Text>
		</TouchableOpacity>);
	}

    return (
		<View style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			height: Common.getLengthByIPhone7(44),
			borderRadius: Common.getLengthByIPhone7(14),
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'space-between',
			backgroundColor: colors.BG_VIEW,
			paddingLeft: Common.getLengthByIPhone7(4),
			paddingRight: Common.getLengthByIPhone7(4),
			marginBottom: Common.getLengthByIPhone7(6),
		}}>
			{renderButton('Дела', -1)}
			{renderButton('АС', 0)}
			{renderButton('СОЮ', 1)}
			{renderButton('Компании', 2)}
		</View>
	);
};

const mstp = (state: RootState) => ({
	buttonIndex: state.buttons.buttonIndex,
});

const mdtp = (dispatch: Dispatch) => ({
	setButtonIndex: payload => dispatch.buttons.setButtonIndex(payload),
});

export default connect(mstp, mdtp)(ButtonView);