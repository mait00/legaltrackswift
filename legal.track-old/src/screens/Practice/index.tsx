import React, { useCallback, useEffect, useRef } from 'react';
import { ScrollView, StatusBar, View, TouchableOpacity, FlatList, Text } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import {colors} from './../../styles';
import AddView from '../../components/Practice/AddView';
import KeywordView from '../../components/Practice/KeywordView';

const PracticeScreen = ({keywordsList, userProfile}) => {

	const navigation = useNavigation();

    const [body, setBody] = React.useState(null);

    useEffect(() => {
        let array = [];
        array.push(<AddView/>);
        for (let i = 0; i < keywordsList.length; i++) {
            array.push(<KeywordView
                data={keywordsList[i]}
                index={i}
                action={() => {
                    navigation.navigate('Keyword', {data: keywordsList[i]});
                }}
            />);
        }
        setBody(array);
    }, [keywordsList]);

	const renderRow = (item: object, index: number) => {
		console.warn(item);
		return (<KeywordView
			data={item}
			index={index}
			action={() => {
				navigation.navigate('Keyword', {data: item});
			}}
		/>);
    }

    const renderAlert = () => {
		return (<View style={{
			width: Common.getLengthByIPhone7(0),
			flex: 1,
			alignItems: 'center',
			justifyContent: 'center',
		}}>
			<Text style={{
				width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
				color: colors.TEXT_COLOR,
				fontFamily: 'SFProDisplay-Regular',
				fontWeight: '600',
				textAlign: 'center',
				fontSize: Common.getLengthByIPhone7(20),
			}}
			allowFontScaling={false}>
				Данная функция недоступна в бесплатном тарифе, оплатите тариф и используйте весь функционал приложения
			</Text>
			<TouchableOpacity style={{
				marginTop: Common.getLengthByIPhone7(20),
				width: Common.getLengthByIPhone7(150),
				height: Common.getLengthByIPhone7(40),
				borderRadius: Common.getLengthByIPhone7(10),
				alignItems: 'center',
				justifyContent: 'center',
				backgroundColor: colors.ORANGE_COLOR,
			}}
			onPress={() => {
				navigation.navigate('Tarifs');
			}}>
				<Text style={{
					color: 'white',
					fontFamily: 'SFProDisplay-Regular',
					fontWeight: '600',
					textAlign: 'center',
					fontSize: Common.getLengthByIPhone7(16),
				}}
				allowFontScaling={false}>
					Тарифы
				</Text>
			</TouchableOpacity>
		</View>);
	}

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'flex-start',
        }}>
            {!userProfile.is_tarif_active ? (renderAlert()) : (<ScrollView
                style={{
                    width: Common.getLengthByIPhone7(0),
                    flex: 1,
                }}
                contentContainerStyle={{
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                }}
            >
                {body}
            </ScrollView>)}
		</View>
	);
};

const mstp = (state: RootState) => ({
	keywordsList: state.all.keywordsList,
    userProfile: state.user.userProfile,
});

const mdtp = (dispatch: Dispatch) => ({
    // getBills: () => dispatch.bills.getBills(),
	// setSelectedBill: payload => dispatch.bills.setSelectedBill(payload),
	// getBalance: payload => dispatch.bills.getBalance(payload),
});

export default connect(mstp, mdtp)(PracticeScreen);
