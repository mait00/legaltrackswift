import React, { useCallback, useEffect, useRef } from 'react';
import { Linking, View, TouchableOpacity, ScrollView, Text, Image, Share, Alert } from 'react-native';
import { RootState, Dispatch } from './../../store';
import { connect, useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import Common from '../../utilities/Common';
import { colors } from '../../styles';
import { APP_NAME } from '../../constants';
import Toast from 'react-native-simple-toast';
import Clipboard from '@react-native-clipboard/clipboard';

const OkvedsScreen = ({route, getCompany}) => {

	// const { data } = route.params;

	const [body, setBody] = React.useState(null);
	const [data, setData] = React.useState(null);

	useEffect(() => {
		setData(route.params.data);
	}, []);

	useEffect(() => {

		if (data === null || data.length === 0) {
			setBody(<View style={{
				flex: 1,
				width: Common.getLengthByIPhone7(0),
				justifyContent: 'center',
				alignItems: 'center',
				backgroundColor: 'white',
			  }}>
					<Text style={{
						color: 'black',
						fontFamily: 'Montserrat-Regular',
						fontWeight: 'normal',
						textAlign: 'center',
						fontSize: Common.getLengthByIPhone7(16),
						// lineHeight: Common.getLengthByIPhone7(15),
					}}
					allowFontScaling={false}>
						Данных нет
					</Text>
			  </View>);
		}
	
		let okveds = [];
	
		if (data !== null) {
			for (let i = 0; i < data.length; i++) {
				okveds.push(renderField(data[i].name + ' (' + data[i].code + ')'));
			}
		}

		setBody(<View style={{
			flex: 1,
			width: Common.getLengthByIPhone7(0),
			// height: Dimensions.get('window').height,
			justifyContent: 'flex-start',
			alignItems: 'center',
			backgroundColor: 'white',
			// marginTop: Common.getLengthByIPhone7(18)
		  }}>
				<Text style={{
					marginBottom: Common.getLengthByIPhone7(15),
					width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
					color: colors.TEXT_COLOR,
					fontFamily: 'Montserrat-Bold',
					fontWeight: 'bold',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(24),
				}}
				allowFontScaling={false}>
					Виды деятельности
				</Text>
				<ScrollView style={{
					width: Common.getLengthByIPhone7(0),
					flex: 1,
				}}
				contentContainerStyle={{
					alignItems: 'center',
				}}>
					{okveds}
				</ScrollView>
		  </View>);
	}, [data]);

	const renderField = title => {
        return (<View style={{
            width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
            borderBottomWidth: 1,
            borderBottomColor: 'rgba(0, 0, 0, 0.2)',
            marginTop: Common.getLengthByIPhone7(15),
            paddingBottom: Common.getLengthByIPhone7(15),
        }}>
            <Text style={{
                color: colors.TEXT_COLOR,
                fontFamily: 'Montserrat-Regular',
                fontWeight: 'normal',
                textAlign: 'left',
                fontSize: Common.getLengthByIPhone7(15),
                marginTop: Common.getLengthByIPhone7(10),
            }}
            allowFontScaling={false}>
                {title}
            </Text>
        </View>);
    }

	return (
        <View style={{
            flex: 1,
            backgroundColor: 'white',
			alignItems: 'center',
			justifyContent: 'center',
        }}>
			{body}
		</View>
	);
};

const mstp = (state: RootState) => ({
	// currentCase: state.all.currentCase,
});

const mdtp = (dispatch: Dispatch) => ({
    getCompany: payload => dispatch.all.getCompany(payload),
	// renameCase: payload => dispatch.all.renameCase(payload),
	// getSubscribtions: () => dispatch.all.getSubscribtions(),
});

export default connect(mstp, mdtp)(OkvedsScreen);
