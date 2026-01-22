//@ts-nocheck
import { createModel } from '@rematch/core';
import { API, StorageHelper } from './../../services';
import { ErrorsHelper } from './../../helpers';
import { Dispatch } from 'store';
import type { RootModel } from './../models';

type UserState = {
	isRequestGoing: false,
	userProfile: null,
};

const user = createModel<RootModel>()({
	state: {
		isRequestGoing: false,
		userProfile: null,
	} as UserState, 
	reducers: {
		setRequestGoingStatus: (state, payload: boolean) => ({
			...state,
			isRequestGoing: payload,
		}),
		setUserProfile: (state, payload: object) => ({
			...state,
			userProfile: payload,
		}),
	},
	effects: (dispatch) => {
		return {
			async getCode(phone) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.getCode(phone)
					.then(response => {
						console.warn('getCode -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							resolve();
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async sendCode(phone, code) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.sendCode(phone, code)
					.then(response => {
						console.warn('sendCode -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							StorageHelper.saveData('token', response.data.token);
							API.setToken(response.data.token);
							resolve()
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async getProfile() {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.getProfile()
					.then(response => {
						console.warn('getProfile -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							dispatch.user.setUserProfile(response.data.data);
							resolve(response.data.data)
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
						reject('Произошла неизвестная ошибка! Повторите снова.');
					});
				});
			},
			async logout() {
				return new Promise((resolve, reject) => {
					dispatch.user.setUserProfile(null);
					StorageHelper.saveData('token', '');
					API.setToken(null);
				});
			},
			async editProfile(first_name, last_name, email, type) {
				return new Promise((resolve, reject) => {
					dispatch.user.setRequestGoingStatus(true);
					API.common.editProfile(first_name, last_name, email, type)
					.then(response => {
						console.warn('editProfile -> response', response);
						dispatch.user.setRequestGoingStatus(false);
						if (response.status == 200) {
							dispatch.user.setUserProfile(response.data.data);
							resolve(response.data.data)
						} else {
							reject(response.data.message);
						}
					})
					.catch(err => {
						dispatch.user.setRequestGoingStatus(false);
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

export default user;