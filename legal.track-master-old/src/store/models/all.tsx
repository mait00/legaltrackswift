//@ts-nocheck
import { createModel } from '@rematch/core';
import { API, StorageHelper } from './../../services';
import { ErrorsHelper } from './../../helpers';
import { Dispatch } from 'store';
import type { RootModel } from './../models';

type AllState = {
	isRequestGoing: false,
	notificationList: [],
	delayList: [],
	messageList: [],
	allSubscriptions: [],
	casesList: [],
	companiesList: [],
	keywordsList: [],
};

const all = createModel<RootModel>()({
	state: {
		isRequestGoing: false,
		notificationList: [],
		delayList: [],
		messageList: [],
		allSubscriptions: [],
		casesList: [],
		companiesList: [],
		keywordsList: [],
	} as AllState, 
	reducers: {
		setNotificationList: (state, payload) => ({
			...state,
			notificationList: payload,
		}),
		setDelayList: (state, payload) => ({
			...state,
			delayList: payload,
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
	},
	effects: (dispatch) => {
		return {
			async getNotifications() {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
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
					dispatch.user.setRequestGoingStatus(true);
					API.common.getDelays()
					.then(response => {
						console.warn('getDelays -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							dispatch.all.setDelayList(response.data.data);
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
					dispatch.user.setRequestGoingStatus(true);
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
					dispatch.user.setRequestGoingStatus(true);
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
			async endLoading(): Promise<any> {
				dispatch.user.setRequestGoingStatus(false);
			},
		}
	},
});

export default all;