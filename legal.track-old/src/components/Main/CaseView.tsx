import React, { useEffect } from 'react';
import {Platform, Image, View, Text, TouchableOpacity} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import Common from '../../utilities/Common';
import { colors } from '../../styles';

const CaseView = ({data, action, index, onShowMenu}) => {

	const renderSide = (style, icon, title) => {
		return (<View style={[{
			borderColor: 'rgba(50, 38, 97, 0.09)',
			borderWidth: 1,
			maxWidth: Common.getLengthByIPhone7(305),
			borderRadius: Common.getLengthByIPhone7(8),
			paddingTop: Common.getLengthByIPhone7(6),
			paddingBottom: Common.getLengthByIPhone7(6),
			paddingLeft: Common.getLengthByIPhone7(10),
			paddingRight: Common.getLengthByIPhone7(10),
			flexDirection: 'row',
			alignItems: 'flex-start',
			justifyContent: 'flex-start',
			flex: 0,
		}, style]}>
			<Image source={icon}
				style={{
					width: Common.getLengthByIPhone7(16),
					height: Common.getLengthByIPhone7(16),
					resizeMode: 'contain',
				}}
			/>
			<Text style={{
				marginLeft: 6,
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: '600',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(11),
			}}
			allowFontScaling={false}>
				{title}
			</Text>
		</View>);
	}

    return (
		<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			marginTop: index === 0 ? Common.getLengthByIPhone7(10) : 0,
			borderRadius: Common.getLengthByIPhone7(12),
			marginBottom: Common.getLengthByIPhone7(10),
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
			console.warn(data);
			action();
		}}>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				minHeight: Common.getLengthByIPhone7(36),
				backgroundColor: data.status === 'loading' ? 'rgba(244, 244, 244, 1)' : '#EAE9EF',
				borderTopLeftRadius: Common.getLengthByIPhone7(12),
				borderTopRightRadius: Common.getLengthByIPhone7(12),
				paddingLeft: Common.getLengthByIPhone7(15),
				paddingTop: Common.getLengthByIPhone7(4),
				paddingBottom: Common.getLengthByIPhone7(4),
				flexDirection: 'row',
				alignItems: 'center',
				justifyContent: 'space-between',
			}}>
				<View style={{
					alignItems: 'center',
					justifyContent: 'flex-start',
					flexDirection: 'row',
				}}>
					{data.status === 'loading' || data.status === 'not_found' ? (<Image source={require('./../../assets/ic-clock-glass.png')}
						style={{
							width: Common.getLengthByIPhone7(30),
							height: Common.getLengthByIPhone7(30),
							resizeMode: 'contain',
						}}
					/>) : null}
					<View style={{

					}}>
						<Text style={{
							maxWidth: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(90),
							marginLeft: 2,
							color: data.status === 'loading' || data.status === 'not_found' ? 'rgba(66, 67, 71, 0.5)' : colors.MAIN_COLOR,
							fontFamily: 'SFProDisplay-Regular',
							fontWeight: (Platform.OS === 'ios' ? '600' : 'bold'),
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(16),
						}}
						allowFontScaling={false}>
							{data.name !== null ? data.name : data.value}
						</Text>
						{data.status === 'loading' || data.status === 'not_found' ? (<Text style={{
							marginLeft: 2,
							color: 'rgba(66, 67, 71, 0.5)',
							fontFamily: 'SFProDisplay-Regular',
							fontWeight: 'normal',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(10),
						}}
						allowFontScaling={false}>
							{data.status === 'loading' ? 'Синхронизация...' : 'Дело не найдено'}
						</Text>) : null}
					</View>
				</View>
				<TouchableOpacity style={{
					width: Common.getLengthByIPhone7(32),
					height: Common.getLengthByIPhone7(40),
					alignItems: 'center',
					justifyContent: 'center',
				}}
				onPress={() => {
					onShowMenu();
				}}>
					<View style={{
						width: Common.getLengthByIPhone7(5),
						height: Common.getLengthByIPhone7(5),
						borderRadius: Common.getLengthByIPhone7(5)/2,
						backgroundColor: colors.TEXT_COLOR,
					}} />
					<View style={{
						marginTop: Common.getLengthByIPhone7(2),
						width: Common.getLengthByIPhone7(5),
						height: Common.getLengthByIPhone7(5),
						borderRadius: Common.getLengthByIPhone7(5)/2,
						backgroundColor: colors.TEXT_COLOR,
					}} />
					<View style={{
						marginTop: Common.getLengthByIPhone7(2),
						width: Common.getLengthByIPhone7(5),
						height: Common.getLengthByIPhone7(5),
						borderRadius: Common.getLengthByIPhone7(5)/2,
						backgroundColor: colors.TEXT_COLOR,
					}} />
				</TouchableOpacity>
			</View>
			<View style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				backgroundColor: 'white',
				borderBottomLeftRadius: Common.getLengthByIPhone7(12),
				borderBottomRightRadius: Common.getLengthByIPhone7(12),
				paddingLeft: Common.getLengthByIPhone7(15),
				paddingRight: Common.getLengthByIPhone7(15),
				paddingTop: Common.getLengthByIPhone7(8),
				paddingBottom: Common.getLengthByIPhone7(10),
			}}>
				{data.status === 'loading' || data.status === 'not_found' ? (<Text style={{
					color: 'rgba(66, 67, 71, 0.5)',
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(11),
				}}
				allowFontScaling={false}>
					{data.status === 'loading' ? `Идет синхронизация дела...\nСинхронизация может занять от 2 до 20 минут` : ''}
				</Text>) : (<View style={{
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(70),
				}}>
					{data.side_pl ? renderSide({}, require('./../../assets/ic-sword.png'), data.side_pl) : null}
					{data.side_df ? renderSide({marginTop: data.side_pl ? Common.getLengthByIPhone7(8) : 0}, require('./../../assets/ic-shield.png'), data.side_df) : null}
				</View>)}
			</View>
		</TouchableOpacity>
	);
};

export default CaseView;