import React, { useCallback, useEffect, useRef } from 'react';
import { StyleSheet, ScrollView, View, TouchableOpacity, Image, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';

const TarifsScreen = ({bills, getBills, setSelectedBill, getBalance}) => {

	const navigation = useNavigation();

	renderTarif = (backgroundColor, icon, name, title, subtitle, subtitle2, action) => {
		return (<TouchableOpacity style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			height: Common.getLengthByIPhone7(114),
			borderRadius: Common.getLengthByIPhone7(11),
			backgroundColor: backgroundColor,
			marginBottom: Common.getLengthByIPhone7(8),
			paddingLeft: Common.getLengthByIPhone7(14),
			flexDirection: 'row',
			alignItems: 'center',
			justifyContent: 'flex-start',
		}}
		onPress={() => {
			action();
		}}>
			<Image source={icon}
				style={{
					width: Common.getLengthByIPhone7(89),
					height: Common.getLengthByIPhone7(89),
					resizeMode: 'contain',
				}}
			/>
			<View style={{
				marginLeft: Common.getLengthByIPhone7(20),
			}}>
				<Text style={{
					// marginTop: Common.getLengthByIPhone7(18),
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(16),
					lineHeight: Common.getLengthByIPhone7(19),
				}}
				allowFontScaling={false}>
					{name}
				</Text>
				<Text style={{
					marginTop: Common.getLengthByIPhone7(2),
					color: colors.TEXT_COLOR,
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(12),
					lineHeight: Common.getLengthByIPhone7(14),
				}}
				allowFontScaling={false}>
					{title}
				</Text>
				<View style={{
					marginTop: Common.getLengthByIPhone7(13),
					flexDirection: 'row',
					alignItems: 'center',
				}}>
					<Text style={{
						color: colors.ORANGE_COLOR,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: 'bold',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(18),
						lineHeight: Common.getLengthByIPhone7(21),
					}}
					allowFontScaling={false}>
						{subtitle}
					</Text>
					<Text style={{
						marginLeft: Common.getLengthByIPhone7(7),
						color: colors.TEXT_COLOR,
						fontFamily: 'SFProDisplay-Regular',
						fontWeight: 'normal',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(12),
						lineHeight: Common.getLengthByIPhone7(14),
						textDecorationLine: 'line-through',
					}}
					allowFontScaling={false}>
						{subtitle2}
					</Text>
				</View>
			</View>
		</TouchableOpacity>);
	}

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			<ScrollView style={{
				width: Common.getLengthByIPhone7(0),
				flex: 1,
				backgroundColor: 'white',
			}}
			contentContainerStyle={{
				alignItems: 'center',
				justifyContent: 'flex-start',
			}}>
				{renderTarif('rgba(235, 94, 31, 0.05)', require('./../../assets/ic-tarif-prof.png'), 'Профессиональный 1', '1 месяц', '1490 р.', () => {

				})}
				{renderTarif('rgba(235, 94, 31, 0.05)', require('./../../assets/ic-tarif-prof.png'), 'Профессиональный 2', '6 месяцев', '6250 р.', '8940 p.', () => {

				})}
				{renderTarif('rgba(235, 94, 31, 0.05)', require('./../../assets/ic-tarif-prof.png'), 'Профессиональный 3', '1 год', '8940 р.', '17880 p.', () => {

				})}
				{renderTarif('rgba(50, 38, 97, 0.1)', require('./../../assets/ic-tarif-corp.png'), 'Корпоративный 1', '1 год за сотрудника', '7940 р.', () => {

				})}
				{renderTarif('rgba(50, 38, 97, 0.1)', require('./../../assets/ic-tarif-corp.png'), 'Корпоративный 2', '1 год за 10 сотрудника', '47940 р.', () => {

				})}
				{renderTarif('rgba(50, 38, 97, 0.1)', require('./../../assets/ic-tarif-corp.png'), 'Корпоративный 3', '1 год, безлимитное кол-во сотрудников', '76940 р.', () => {
					
				})}
			</ScrollView>
		</View>
	);
};

const mstp = (state: RootState) => ({
	// bills: state.bills.bills,
});

const mdtp = (dispatch: Dispatch) => ({
    // getBills: () => dispatch.bills.getBills(),
	// setSelectedBill: payload => dispatch.bills.setSelectedBill(payload),
	// getBalance: payload => dispatch.bills.getBalance(payload),
});

export default connect(mstp, mdtp)(TarifsScreen);
