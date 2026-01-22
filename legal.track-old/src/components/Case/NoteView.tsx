import React, { useEffect, useRef } from 'react';
import {Platform, Image, View, Text, TouchableOpacity, ActivityIndicator, Animated, Easing} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';

const NoteView = ({data, onClick}) => {

	const [openView, setOpenView] = React.useState(false);

	return (<TouchableOpacity style={{
		width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
		minHeight: Common.getLengthByIPhone7(44),
		marginBottom: Common.getLengthByIPhone7(8),
		borderRadius: Common.getLengthByIPhone7(12),
		paddingLeft: Common.getLengthByIPhone7(8),
		paddingRight: Common.getLengthByIPhone7(8),
		backgroundColor: 'white',
		flexDirection: 'row',
		alignItems: 'center',
		justifyContent: 'space-between',
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
		if (onClick) {
			onClick();
		}
	}}>
		<View style={{
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'flex-start',
		}}>
			<Image source={require('./../../assets/ic-note.png')} 
				style={{
					width: Common.getLengthByIPhone7(30),
					height: Common.getLengthByIPhone7(30),
					resizeMode: 'contain',
				}}
			/>
			<Text style={{
				// backgroundColor: 'red',
				width: Common.getLengthByIPhone7(220),
				marginLeft: 3,
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(14),
				lineHeight: Common.getLengthByIPhone7(17),
			}}
			numberOfLines={1}
			allowFontScaling={false}>
				{data.text}
			</Text>
		</View>
		<Text style={{
			color: colors.TEXT_COLOR,
			fontFamily: 'SFProDisplay-Regular',
			fontWeight: 'normal',
			textAlign: 'left',
			fontSize: Common.getLengthByIPhone7(10),
			lineHeight: Common.getLengthByIPhone7(12),
			opacity: 0.5,
		}}
		allowFontScaling={false}>
			{Common.getRusDate(new Date(data.created_at))}
		</Text>
	</TouchableOpacity>);
};

const mstp = (state: RootState) => ({
	// currentCase: state.all.currentCase,
});

const mdtp = (dispatch: Dispatch) => ({
    // setShowRecord: payload => dispatch.buttons.setShowRecord(payload),
});

export default connect(mstp, mdtp)(NoteView);