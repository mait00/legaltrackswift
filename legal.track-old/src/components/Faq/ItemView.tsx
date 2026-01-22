import React, { useEffect, useRef } from 'react';
import {StyleSheet, Image, View, Text, TouchableOpacity, Linking, Animated, Easing} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';

const ItemView = ({style, data}) => {

	const [openView, setOpenView] = React.useState(false);
	const [tags, setTags] = React.useState(null);

	const opacity = useRef(new Animated.Value(0));
	const height = useRef(new Animated.Value(0));

	useEffect(() => {
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
			<Text style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(80),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(12),
				lineHeight: Common.getLengthByIPhone7(24),
				marginBottom: Common.getLengthByIPhone7(6),
			}}
			allowFontScaling={false}>
				{data.text}
			</Text>
		</Animated.View>);
	}, [data]);

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
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(110),
					// backgroundColor: 'red',
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'bold',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(14),
					lineHeight: Common.getLengthByIPhone7(17),
				}}
				allowFontScaling={false}>
					{data.header}
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

export default ItemView;