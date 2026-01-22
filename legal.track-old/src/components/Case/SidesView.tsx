import React, { useEffect, useRef } from 'react';
import {StyleSheet, Image, View, Text, TouchableOpacity, Animated, Easing} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import Tags from "react-native-tags";

const SidesView = ({title, style, icon, data}) => {

	const [openView, setOpenView] = React.useState(true);
	const [tags, setTags] = React.useState(null);

	const opacity = useRef(new Animated.Value(1));
	const height = useRef(new Animated.Value(1));

	useEffect(() => {
		setTags(<Animated.View style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			marginBottom: Common.getLengthByIPhone7(10),
			opacity: 1,//opacity.current,
			maxHeight: height.current.interpolate({ 
				inputRange: [0, 1], 
				outputRange: [0, 10000]
			})
		}}>
			<Tags
				readonly
				initialTags={data}
				containerStyle={{ justifyContent: "flex-start" }}
				renderTag={({ tag, index, onPress, deleteTagOnPress, readonly }) => (
					<Animated.View style={{
						backgroundColor: '#F4F4F4',
						borderRadius: Common.getLengthByIPhone7(6),
						padding: height.current.interpolate({ 
							inputRange: [0, 0.2, 1], 
							outputRange: [0, 5.5, 6]
						}),
						// paddingLeft: Common.getLengthByIPhone7(6),
						// paddingRight: Common.getLengthByIPhone7(6),
						margin: Common.getLengthByIPhone7(5),
					}} key={`${tag}-${index}`}>
						<Text style={{
							color: colors.TEXT_COLOR,
							fontFamily: 'SFProText-Regular',
							fontWeight: 'normal',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(14),
							lineHeight: Common.getLengthByIPhone7(20),
						}}>
							{tag}
						</Text>
					</Animated.View>
				)}
			/>
		</Animated.View>);
	}, [data]);

    return (
		<View style={[{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			minHeight: Common.getLengthByIPhone7(54),
			backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'flex-start',
		}, style]}>
			<TouchableOpacity style={{
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'space-between',
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
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
				<View style={{
					flexDirection: 'row',
					alignItems: 'center',
				}}>
					<Image
						source={icon}
						style={{
							resizeMode: 'contain',
							width: Common.getLengthByIPhone7(16),
							height: Common.getLengthByIPhone7(16),
						}}
					/>
					<Text style={{
						marginLeft: Common.getLengthByIPhone7(7),
						color: colors.TEXT_COLOR,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: '600',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(20),
						lineHeight: Common.getLengthByIPhone7(28),
					}}
					allowFontScaling={false}>
						{title}
					</Text>
				</View>
				<Text style={{
					color: colors.ORANGE_COLOR,
					fontFamily: 'SFProText-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(14),
					lineHeight: Common.getLengthByIPhone7(22),
				}}
				allowFontScaling={false}>
					{openView ? 'Скрыть' : 'Показать'}
				</Text>
			</TouchableOpacity>
			{tags}
		</View>
	);
};

export default SidesView;