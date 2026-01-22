//@ts-nocheck
import { createModel } from '@rematch/core';
import { API, StorageHelper } from './../../services';
import { ErrorsHelper } from './../../helpers';
import { Dispatch } from 'store';
import type { RootModel } from './../models';
import AsyncStorage from '@react-native-async-storage/async-storage';

type AllState = {
	isRequestGoing: false,
	notificationList: [],
	delayList: [],
	delayRawList: [],
	messageList: [],
	allSubscriptions: [],
	casesList: [],
	companiesList: [],
	keywordsList: [],
	currentCase: null,
	courtList: [],
	instancesList: [],
	faqList: [],
	categoriesList: [],
	barcodeList: null,
	getCurrCase: null,
};

const all = createModel<RootModel>()({
	state: {
		isRequestGoing: false,
		notificationList: [],
		delayList: [],
		delayRawList: [],
		messageList: [],
		allSubscriptions: [],
		faqList: [],
		casesList: [],
		companiesList: [],
		keywordsList: [],
		currentCase: null,
		courtList: [],
		instancesList: [],
		categoriesList: [],
		barcodeList: null,
		getCurrCase: null,
	} as AllState, 
	reducers: {
		setBarcodeList: (state, payload) => ({
			...state,
			barcodeList: payload,
		}),
		setCurrCase: (state, payload) => ({
			...state,
			getCurrCase: payload,
		}),
		setNotificationList: (state, payload) => ({
			...state,
			notificationList: payload,
		}),
		setDelayList: (state, payload) => ({
			...state,
			delayList: payload,
		}),
		setDelayRawList: (state, payload) => ({
			...state,
			delayRawList: payload,
		}),
		setFaqList: (state, payload) => ({
			...state,
			faqList: payload,
		}),
		setAllSubscriptions: (state, payload) => ({
			...state,
			allSubscriptions: payload,
		}),
		setCasesList: (state, payload) => ({
			...state,
			casesList: payload,
		}),
		setCompaniesList: (state, payload) => ({
			...state,
			companiesList: payload,
		}),
		setKeywordsList: (state, payload) => ({
			...state,
			keywordsList: payload,
		}),
		setMessageList: (state, payload) => ({
			...state,
			messageList: payload,
		}),
		setCurrentCase: (state, payload) => ({
			...state,
			currentCase: payload,
		}),
		setCourtList: (state, payload) => ({
			...state,
			courtList: payload,
		}),
		setCategoriesList: (state, payload) => ({
			...state,
			categoriesList: payload,
		}),
		setInstancesList: (state, payload) => ({
			...state,
			instancesList: payload,
		}),
	},
	effects: (dispatch) => {
		return {
			async getNotifications() {
				return new Promise((resolve, reject) => {
					// dispatch.user.setRequestGoingStatus(true);
					API.common.getNotifications()
					.then(response => {
						console.warn('getNotifications -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							dispatch.all.setNotificationList(response.data.data);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getDelay() {
				return new Promise((resolve, reject) => {
					// dispatch.user.setRequestGoingStatus(true);
					API.common.getDelays()
					.then(response => {
						console.warn('getDelays -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							dispatch.all.setDelayList(response.data.data);
							dispatch.all.setDelayRawList(response.data.data);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getSubscribtions() {
				return new Promise((resolve, reject) => {
					// dispatch.user.setRequestGoingStatus(true);
					API.common.getSubscribtions()
					.then(response => {
						console.warn('getSubscribtions -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							dispatch.all.setAllSubscriptions(response.data.data.cases);
							dispatch.all.setCasesList(response.data.data.cases);
							dispatch.all.setCompaniesList(response.data.data.companies);
							dispatch.all.setKeywordsList(response.data.data.keywords);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getMessages() {
				return new Promise((resolve, reject) => {
					// dispatch.user.setRequestGoingStatus(true);
					API.common.getMessages()
					.then(response => {
						console.warn('getMessages -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							dispatch.all.setMessageList(response.data.data);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async sendMessage(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.sendMessage(payload)
					.then(response => {
						console.warn('sendMessage -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async setPushId(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.setPushId(payload)
					.then(response => {
						console.warn('setPushId -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async deleteSubscription(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.deleteSubscription(payload.id, payload.type)
					.then(response => {
						console.warn('deleteSubscription -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async renameCase(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.renameCase(payload.id, payload.name)
					.then(response => {
						console.warn('renameCase -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async renameCompany(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.renameCompany(payload.id, payload.name)
					.then(response => {
						console.warn('renameCompany -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async renameAudio(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					console.warn('payload: ', payload);
					API.common.renameAudio(payload.id, payload.name)
					.then(response => {
						console.warn('renameAudio -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve(response.data.data);
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getCase(id) {
				return new Promise((resolve, reject) => {
					dispatch.all.setCurrentCase(null);
					dispatch.user.setRequestGoingStatus(true);
					API.common.getCase(id)
					.then(response => {
						console.warn('getCase -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							dispatch.all.setCurrentCase(response.data.data);
							resolve(response.data.data);
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getCompany(id) {
				return new Promise((resolve, reject) => {
					dispatch.all.setCurrentCase(null);
					dispatch.user.setRequestGoingStatus(true);
					API.common.getCompany(id)
					.then(response => {
						console.warn('getCompany -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve(response.data.data);
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getKeyword(id) {
				return new Promise((resolve, reject) => {
					dispatch.all.setCurrentCase(null);
					dispatch.user.setRequestGoingStatus(true);
					API.common.getKeyword(id)
					.then(response => {
						console.warn('getKeyword -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve(response.data.data);
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getCategoriesCases() {
				return new Promise((resolve, reject) => {
					dispatch.all.setCategoriesList([]);
					API.common.getCategoriesCases()
					.then(response => {
						console.warn('getCategoriesCases -> response', response);
						if (response.status == 200) {
							dispatch.all.setCategoriesList(response.data.data);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getCalendar() {
				return new Promise((resolve, reject) => {
					// dispatch.user.setRequestGoingStatus(true);
					API.common.getCalendar()
					.then(response => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn('getCalendar -> response', response);
						if (response.status == 200) {
							// dispatch.all.setCategoriesList(response.data.data);
							AsyncStorage.setItem('calendar', JSON.stringify(response.data.data));
							resolve(response.data.data);
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async mutePushCase(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.mutePushCase(payload.id, payload.mute_all)
					.then(response => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn('mutePushCase -> response', response);
						if (response.status == 200) {
							// dispatch.all.setCategoriesList(response.data.data);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async muteSidesCase(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.muteSidesCase(payload.id, payload.muted_list)
					.then(response => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn('muteSidesCase -> response', response);
						if (response.status == 200) {
							// dispatch.all.setCategoriesList(response.data.data);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async searchDelays(payload) {
				return new Promise((resolve, reject) => {
					// dispatch.user.setRequestGoingStatus(true);
					API.common.searchDelays(payload)
					.then(response => {
						// dispatch.user.setRequestGoingStatus(false);
						console.warn('searchDelays -> response', response);
						if (response.status == 200) {
							// dispatch.all.setCategoriesList(response.data.data);
							resolve(response.data.data);
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						// dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getCourts() {
				return new Promise((resolve, reject) => {
					dispatch.all.setCourtList([]);
					API.common.getCourts()
					.then(response => {
						console.warn('getCourts -> response', response);
						if (response.status == 200) {
							dispatch.all.setCourtList(response.data.data);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getInstances() {
				return new Promise((resolve, reject) => {
					dispatch.all.setInstancesList([]);
					API.common.getInstances()
					.then(response => {
						console.warn('getInstances -> response', response);
						if (response.status == 200) {
							dispatch.all.setInstancesList(response.data.data);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getFaq() {
				return new Promise((resolve, reject) => {
					dispatch.all.setInstancesList([]);
					API.common.getFaq()
					.then(response => {
						console.warn('getFaq -> response', response);
						if (response.status == 200) {
							dispatch.all.setFaqList(response.data.list);
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async newSubscription(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.newSubscription(payload.type, payload.value, payload.sou)
					.then(response => {
						console.warn('newSubscription -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err.response);
						if (err.response) {
							reject(err.response.data.message);
						} else {
							reject('Произошла неизвестная ошибка! Повторите снова.');
						}
					});
				});
			},
			async editKeyword(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.editKeyword(payload)
					.then(response => {
						console.warn('editKeyword -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async searchCompanies(query) {
				return new Promise((resolve, reject) => {
					// dispatch.user.setRequestGoingStatus(true);
					API.common.searchCompanies(query)
					.then(response => {
						console.warn('searchCompanies -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve(response.data.suggestions);
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async endLoading(): Promise<any> {
				dispatch.user.setRequestGoingStatus(false);
			},
			async setDelayRawList(payload): Promise<any> {
				dispatch.all.setDelayList(payload);
			},
			async uploadAudio(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.uploadAudio(payload.id, payload.file)
					.then(response => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn('uploadAudio -> response', response);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async addNote(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.addNote(payload.id, payload.text)
					.then(response => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn('addNote -> response', response);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async updateNote(payload) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.updateNote(payload.id, payload.text)
					.then(response => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn('updateNote -> response', response);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async validateReceipt(payload) {
				return new Promise((resolve, reject) => {
					// dispatch.user.setRequestGoingStatus(true);
					API.common.validateReceipt(payload.receipt, payload.store_type, payload.tarif)
					.then(response => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn('validateReceipt -> response', response);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						console.warn(err);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
		}
	},
});

export default all;