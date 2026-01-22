import React, { useEffect, useRef } from 'react';
import {StyleSheet, Image, View, Text, TouchableOpacity, Linking, Animated, Easing} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import ItemModalView from '../Main/ItemModalView';

const InstanceView = ({title, style, icon, data, data2}) => {

	const [openView, setOpenView] = React.useState(true);
	const [tags, setTags] = React.useState(null);

	const opacity = useRef(new Animated.Value(1));
	const height = useRef(new Animated.Value(1));

	useEffect(() => {
		let array = [];

		// console.warn(data);
		for (let i = 0; i < data.length; i++) {
			array.push(renderView(data[i]));
		}
		setTags(<Animated.View style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			alignItems: 'center',
			opacity: 1,//opacity.current,
			maxHeight: height.current.interpolate({ 
				inputRange: [0, 1], 
				outputRange: [0, 10000]
			}),
			overflow: 'hidden',
		}}>
			{array}
		</Animated.View>);
	}, [data]);

	const renderView = item => {
		return (<View style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
			paddingTop: Common.getLengthByIPhone7(7),
			paddingBottom: Common.getLengthByIPhone7(7),
		}}>
			<View style={{
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'flex-start',
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
			}}>
				<Image
					source={require('./../../assets/ic-calendar.png')}
					style={{
						resizeMode: 'contain',
						width: Common.getLengthByIPhone7(24),
						height: Common.getLengthByIPhone7(24),
					}}
				/>
				<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'bold',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(12),
					lineHeight: Common.getLengthByIPhone7(14),
				}}
				allowFontScaling={false}>
					{item.date}
				</Text>
				<Text style={{
					marginLeft: Common.getLengthByIPhone7(5),
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(12),
					lineHeight: Common.getLengthByIPhone7(14),
				}}
				allowFontScaling={false}>
					{item.header}
				</Text>
			</View>
			{item.text ? (<Text style={{
				marginTop: 2,
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(14),
				// textDecorationLine: 'underline',
			}}
			allowFontScaling={false}>
				{item.text}
			</Text>) : null}
		</View>);
	}

    return (
		<View style={[{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			// minHeight: Common.getLengthByIPhone7(44),
			marginTop: Common.getLengthByIPhone7(8),
			borderRadius: Common.getLengthByIPhone7(12),
			backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'flex-start',
			shadowColor: "#000",
			shadowOffset: {
				width: 0,
				height: 2,
			},
			shadowOpacity: 0.08,
			shadowRadius: 7.00,
			elevation: 1,
		}, style]}>
			<TouchableOpacity style={{
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'space-between',
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(72),
				minHeight: Common.getLengthByIPhone7(44),
				// backgroundColor: 'red',
				borderBottomColor: colors.TEXT_COLOR,
				borderBottomWidth: openView ? 1 : 0,
			}}
			onPress={() => {
				if (openView) {
					Animated.timing(height.current, {
						toValue: 0,
						duration: 300,
						easing: Easing.linear,
						useNativeDriver: false  // <-- neccessary
					}).start(() => {
						Animated.timing(opacity.current, {
						  toValue: 0,
						  duration: 500,
						  easing: Easing.linear,
						  useNativeDriver: false  // <-- neccessary
						}).start();
					});
				} else {
					Animated.timing(height.current, {
						toValue: 1,
						duration: 500,
						easing: Easing.linear,
						useNativeDriver: false  // <-- neccessary
					}).start(() => {
						Animated.timing(opacity.current, {
						  toValue: 1,
						  duration: 500,
						  easing: Easing.linear,
						  useNativeDriver: false  // <-- neccessary
						}).start();
					});
				}
				setOpenView(!openView);
			}}>
				<Text style={{
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(14),
					lineHeight: Common.getLengthByIPhone7(17),
				}}
				allowFontScaling={false}>
					{title}
				</Text>
				<Image
					source={openView ? require('./../../assets/ic-minus-circle.png') : require('./../../assets/ic-plus-circle.png')}
					style={{
						resizeMode: 'contain',
						width: Common.getLengthByIPhone7(30),
						height: Common.getLengthByIPhone7(30),
					}}
				/>
			</TouchableOpacity>
			{tags}
		</View>
	);
};

export default InstanceView;