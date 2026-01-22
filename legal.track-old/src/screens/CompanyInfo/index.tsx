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

const CompanyInfoScreen = ({route, getCompany}) => {

	// const { data } = route.params;
	const navigation = useNavigation();

	const [body, setBody] = React.useState(null);
	const [data, setData] = React.useState(null);

	useEffect(() => {
		setBody(null);
		getCompany(route.params.data.id)
		.then(response => {
			setData(response);
		})
		.catch(err => {

		});
	}, []);

	const renderField = (title, value) => {
		return (<View style={{
		  width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
		  flexDirection: 'row',
		  alignItems: 'center',
		  justifyContent: 'space-between',
		  marginTop: Common.getLengthByIPhone7(15),
	  }}>
		  <Text style={{
			  color: colors.TEXT_COLOR,
			  fontFamily: 'Montserrat-Bold',
			  fontWeight: 'bold',
			  textAlign: 'left',
			  fontSize: Common.getLengthByIPhone7(15),
		  }}
		  allowFontScaling={false}>
			  {title}
		  </Text>
		  <View style={{
			  height: Common.getLengthByIPhone7(15),
			  flex: 1,
		  }} >
			  <View style={{
				  position: 'absolute',
				  left: 0,
				  top: 0,
				  right: 0,
				  bottom: 0,
				  borderStyle: 'dotted',
				  borderWidth: 2,
				  borderColor: colors.TEXT_COLOR,
			  }} />
			  <View style={{
				  position: 'absolute',
				  left: 0,
				  top: 0,
				  right: 0,
				  bottom: 2,
				  backgroundColor: 'white',
			  }} />
		  </View>
		  <Text style={{
			  color: colors.TEXT_COLOR,
			  fontFamily: 'Montserrat-Bold',
			  fontWeight: 'bold',
			  textAlign: 'left',
			  fontSize: Common.getLengthByIPhone7(15),
		  }}
		  allowFontScaling={false}>
			  {value}
		  </Text>
	  </View>);
	}
  
	const renderField2 = (title, value, value2) => {
		let text2 = null;

		if (value2 !== null) {
			text2 = (<Text style={{
				color: colors.TEXT_COLOR,
				fontFamily: 'Montserrat-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(15),
				marginTop: Common.getLengthByIPhone7(10),
			}}
			allowFontScaling={false}>
				{value2}
			</Text>);
		}
		return (<View style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			borderBottomWidth: 1,
			borderBottomColor: 'rgba(0, 0, 0, 0.2)',
			marginTop: Common.getLengthByIPhone7(15),
			paddingBottom: Common.getLengthByIPhone7(15),
		}}>
			<Text style={{
				color: colors.TEXT_COLOR,
				fontFamily: 'Montserrat-Bold',
				fontWeight: 'bold',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(15),
			}}
			allowFontScaling={false}>
				{title}
			</Text>
			<Text style={{
				color: colors.TEXT_COLOR,
				fontFamily: 'Montserrat-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(15),
				marginTop: Common.getLengthByIPhone7(10),
			}}
			allowFontScaling={false}>
				{value}
			</Text>
			{text2}
		</View>);
	}
  
	const renderOkved = okveds => {
		let text2 = null;

		if (okveds.length > 1) {
			text2 = (<TouchableOpacity style={{
				marginTop: Common.getLengthByIPhone7(10),
			}}
			onPress={() => {
				if (route.name === 'CompanyInfo2') {
					navigation.navigate('Okveds2', {data: okveds});
				} else {
					navigation.navigate('Okveds', {data: okveds});
				}
			}}>
				<Text style={{
					color: colors.MAIN_COLOR,
					fontFamily: 'Montserrat-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(15),
				}}
				allowFontScaling={false}>
					Показать еще ({okveds.length - 1})
				</Text>
			</TouchableOpacity>);
		}

		let value = '';

		for (let i = 0; i < okveds.length; i++) {
			if (okveds[i].main) {
				value = okveds[i].name + ' (' + okveds[i].code + ')';
				break;
			}
		}
		return (<View style={{
			width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			borderBottomWidth: 1,
			borderBottomColor: 'rgba(0, 0, 0, 0.2)',
			marginTop: Common.getLengthByIPhone7(15),
			paddingBottom: Common.getLengthByIPhone7(15),
		}}>
			<Text style={{
				color: colors.TEXT_COLOR,
				fontFamily: 'Montserrat-Bold',
				fontWeight: 'bold',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(15),
			}}
			allowFontScaling={false}>
				Основной вид деятельности
			</Text>
			<Text style={{
				color: colors.TEXT_COLOR,
				fontFamily: 'Montserrat-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(15),
				marginTop: Common.getLengthByIPhone7(10),
			}}
			allowFontScaling={false}>
				{value}
			</Text>
			{text2}
		</View>);
	}
  
	const renderFounder = (title, value, value2) => {
  
		  return (<View style={{
			  width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
			  marginTop: Common.getLengthByIPhone7(15),
		  }}>
			  <Text style={{
				  color: colors.TEXT_COLOR,
				  fontFamily: 'Montserrat-Bold',
				  fontWeight: 'bold',
				  textAlign: 'left',
				  fontSize: Common.getLengthByIPhone7(15),
			  }}
			  allowFontScaling={false}>
				  {title}
			  </Text>
			  <Text style={{
				  color: colors.TEXT_COLOR,
				  fontFamily: 'Montserrat-Regular',
				  fontWeight: 'normal',
				  textAlign: 'left',
				  fontSize: Common.getLengthByIPhone7(15),
				  marginTop: Common.getLengthByIPhone7(10),
			  }}
			  allowFontScaling={false}>
				  {value}
			  </Text>
			  <Text style={{
				  color: colors.TEXT_COLOR,
				  fontFamily: 'Montserrat-Regular',
				  fontWeight: 'normal',
				  textAlign: 'left',
				  fontSize: Common.getLengthByIPhone7(15),
				  marginTop: Common.getLengthByIPhone7(10),
			  }}
			  allowFontScaling={false}>
				  {value2}
			  </Text>
		  </View>);
	}

	const renderStatus = () => {
		let status = (<View style={{
			width: Common.getLengthByIPhone7(170),
			marginBottom: Common.getLengthByIPhone7(5),
			alignItems: 'center',
			justifyContent: 'center',
			borderColor: 'red',
			borderWidth: 1,
			borderRadius: Common.getLengthByIPhone7(13),
			flex: 0,
		}}>
			<Text style={{
				color: 'red',
				fontFamily: 'Montserrat-Regular',
				fontWeight: 'normal',
				textAlign: 'left',
				fontSize: Common.getLengthByIPhone7(14),
				lineHeight: Common.getLengthByIPhone7(25),
			}}
			allowFontScaling={false}>
				ЛИКВИДИРОВАНО
			</Text>
		</View>);
	
		if (data.data.state.status === 'ACTIVE') {
			status = (<View style={{
				width: Common.getLengthByIPhone7(110),
				marginBottom: Common.getLengthByIPhone7(5),
				alignItems: 'center',
				justifyContent: 'center',
				borderColor: 'green',
				borderWidth: 1,
				borderRadius: Common.getLengthByIPhone7(13),
				flex: 0,
			}}>
				<Text style={{
					color: 'green',
					fontFamily: 'Montserrat-Regular',
					fontWeight: 'normal',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(14),
					lineHeight: Common.getLengthByIPhone7(25),
				}}
				allowFontScaling={false}>
					ДЕЙСТВУЕТ
				</Text>
			</View>);
		}
		return status;
	}

	const renderFounders = () => {
		let founders = null;

		if (data.data.founders !== null && data.data.founders !== undefined) {
			let array = [];
			for (let i = 0; i < data.data.founders.length; i++) {
				if (data.data.founders[i].fio !== undefined && data.data.founders[i].fio !== null) {
					array.push(renderFounder(data.data.founders[i].fio.source, 'Доля: ' + (data.data.capital.value*data.data.founders[i].share.value/100) + ` P` + ' (' + data.data.founders[i].share.value + '%)', 'ИНН: ' + data.data.founders[i].inn));
				} else {
					array.push(renderFounder(data.data.founders[i].name, 'Доля: ' + (data.data.capital.value*data.data.founders[i].share.value/100) + ` P` + ' (' + data.data.founders[i].share.value + '%)', 'ИНН: ' + data.data.founders[i].inn));
				}
			}

			founders = (<View style={{
				marginTop: Common.getLengthByIPhone7(10),
				width: Common.getLengthByIPhone7(0),
				padding: Common.getLengthByIPhone7(20),
				backgroundColor: 'white',
			}}>
				<Text style={{
					marginBottom: Common.getLengthByIPhone7(5),
					color: colors.TEXT_COLOR,
					fontFamily: 'Montserrat-Bold',
					fontWeight: 'bold',
					textAlign: 'left',
					fontSize: Common.getLengthByIPhone7(18),
				}}
				allowFontScaling={false}>
					Учредители {data.value}
				</Text>
				{array}
			</View>);
		}
	}

	useEffect(() => {

		if (data) {
			setBody(<ScrollView style={{
				width: Common.getLengthByIPhone7(0),
				flex: 1,
				backgroundColor: '#f1f4fa',
				// marginBottom: Platform.OS === 'ios' ? (isIphoneX() ? 86 : 52) : 52,
			}}
			contentContainerStyle={{
				alignItems: 'center',
			}}>
				<View style={{
					// marginTop: Common.getLengthByIPhone7(20),
					width: Common.getLengthByIPhone7(0),
					padding: Common.getLengthByIPhone7(20),
					backgroundColor: 'white',
				}}>
					{renderStatus()}
					<Text style={{
						marginBottom: Common.getLengthByIPhone7(5),
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
						color: colors.TEXT_COLOR,
						fontFamily: 'Montserrat-Bold',
						fontWeight: 'bold',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(24),
					}}
					allowFontScaling={false}>
						{data.value}
					</Text>
					<Text style={{
						color: colors.TEXT_COLOR,
						fontFamily: 'Montserrat-Bold',
						fontWeight: 'bold',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(14),
					}}
					allowFontScaling={false}>
						{data.data.name.full_with_opf}
					</Text>
				</View>
				<View style={{
					marginTop: Common.getLengthByIPhone7(10),
					width: Common.getLengthByIPhone7(0),
					padding: Common.getLengthByIPhone7(20),
					backgroundColor: 'white',
				}}>
					<Text style={{
						marginBottom: Common.getLengthByIPhone7(5),
						color: colors.TEXT_COLOR,
						fontFamily: 'Montserrat-Bold',
						fontWeight: 'bold',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(22),
					}}
					allowFontScaling={false}>
						Основные показатели
					</Text>
					<Text style={{
						color: colors.TEXT_COLOR,
						fontFamily: 'Montserrat-Regular',
						fontWeight: 'normal',
						textAlign: 'left',
						fontSize: Common.getLengthByIPhone7(14),
						marginBottom: Common.getLengthByIPhone7(10),
					}}
					allowFontScaling={false}>
						Данные на {Common.getRusDate(new Date(data.data.state.actuality_date))}
					</Text>
					<View style={{
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
						flexDirection: 'row',
						alignItems: 'center',
						justifyContent: 'space-between',
					}}>
						<View style={{
							width: Common.getLengthByIPhone7(150),
							minHeight: Common.getLengthByIPhone7(80),
							borderRadius: Common.getLengthByIPhone7(10),
							borderWidth: 1,
							borderColor: colors.TEXT_COLOR,
							padding: Common.getLengthByIPhone7(10),
						}}>
							<Text style={{
								marginBottom: Common.getLengthByIPhone7(5),
								color: colors.TEXT_COLOR,
								fontFamily: 'Montserrat-Bold',
								fontWeight: 'bold',
								textAlign: 'left',
								fontSize: Common.getLengthByIPhone7(15),
							}}
							allowFontScaling={false}>
								Уставный капитал
							</Text>
							{data.data.capital !== null && data.data.capital !== undefined ? (<Text style={{
								color: colors.TEXT_COLOR,
								fontFamily: 'Montserrat-Regular',
								fontWeight: 'normal',
								textAlign: 'left',
								fontSize: Common.getLengthByIPhone7(14),
							}}
							allowFontScaling={false}>
								{data.data.capital.value} &#8381;
							</Text>) : (<Text style={{
								color: colors.TEXT_COLOR,
								fontFamily: 'Montserrat-Regular',
								fontWeight: 'normal',
								textAlign: 'left',
								fontSize: Common.getLengthByIPhone7(14),
							}}
							allowFontScaling={false}>
								н/д
							</Text>)}
						</View>
					</View>
				</View>
				<View style={{
					marginTop: Common.getLengthByIPhone7(10),
					width: Common.getLengthByIPhone7(0),
					padding: Common.getLengthByIPhone7(20),
					backgroundColor: 'white',
				}}>
					<View style={{
						flexDirection: 'row',
						alignItems: 'center',
						justifyContent: 'flex-start',
					}}>
						<Text style={{
							marginBottom: Common.getLengthByIPhone7(5),
							color: colors.TEXT_COLOR,
							fontFamily: 'Montserrat-Bold',
							fontWeight: 'bold',
							textAlign: 'left',
							fontSize: Common.getLengthByIPhone7(15),
						}}
						allowFontScaling={false}>
							Реквизиты {data.value}
						</Text>
						<TouchableOpacity style={{
							marginLeft: Common.getLengthByIPhone7(10),
						}}
						onPress={() => {
							Clipboard.setString('Реквизиты: '+data.value
							+`\nИНН: `+data.data.inn
							+`\nКПП: `+data.data.kpp
							+`\nОГРН: `+data.data.ogrn
							+`\nОКПО: `+data.data.okpo
							+`\nДата создания: `+Common.getRusDate(new Date(data.data.state.registration_date)));
							Toast.show('Реквизиты скопированы');
						}}>
							<Image
								source={require('./../../assets/ic-copy.png')}
								style={{
									width: Common.getLengthByIPhone7(17),
									height: Common.getLengthByIPhone7(17),
									resizeMode: 'contain',
									tintColor: colors.TEXT_COLOR,
								}}
							/>
						</TouchableOpacity>
					</View>
					{renderField('ИНН', data.data.inn)}
					{renderField('КПП', data.data.kpp)}
					{renderField('ОГРН', data.data.ogrn)}
					{renderField('ОКПО', data.data.okpo)}
					{renderField('Дата создания', Common.getRusDate(new Date(data.data.state.registration_date)))}
					{renderField('Кол-во сотрудников', data.data.employee_count !== null ? data.data.employee_count : 'н/д')}
					<View style={{
						marginTop: Common.getLengthByIPhone7(25),
						width: Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(40),
						height: 1,
						backgroundColor: 'rgba(0, 0, 0, 0.2)'
					}} />
					{renderOkved(data.data.okveds)}
					{data.data.documents.smb !== null && data.data.documents.smb !== undefined ? renderField2('Реестр МСП', data.data.documents.smb.category === 'MICRO' ? 'Микропредприятие' : 'Среднее предприятие', 'с ' + Common.getRusDate(new Date(data.data.documents.smb.issue_date))) : null}
					{renderField2('Налоговый орган', data.data.authorities.fts_report.name, 'с ' + Common.getRusDate(new Date(data.data.state.registration_date)))}
					{renderField2('Юридический адрес', data.data.address.value, null)}
					{data.data.management !== null && data.data.management !== undefined ? renderField2('Руководитель', data.data.management.post, data.data.management.name) : null}
				</View>
				{renderFounders()}
				<View style={{
					width: Common.getLengthByIPhone7(0),
					// height: Common.getLengthByIPhone7(10),
				}} />
			</ScrollView>);
		}
	}, [data]);

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

export default connect(mstp, mdtp)(CompanyInfoScreen);
