<script setup>
// SIGMA SOLUTIONS DEVELOPERS
import { computed, onUnmounted, watchEffect } from 'vue';
import { useToggle } from '@vueuse/core';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { emitter } from 'shared/helpers/mitt';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import ResolveAction from '../../buttons/ResolveAction.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router'; 

import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

// --- Setup ---
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const currentUser = useMapGetter('getCurrentUser');
const userRole = computed(() => currentUser.value?.role);
const currentChat = computed(() => store.getters.getSelectedChat);

const [showEmailActionsModal, toggleEmailModal] = useToggle(false);
const [showActionsDropdown, toggleDropdown] = useToggle(false);

// --- Action Menu Items ---
const actionMenuItems = computed(() => {
  const items = [];

  // if (userRole.value === 'administrator') {
  //   if (!currentChat.value.muted) {
  //     items.push({
  //       icon: 'i-lucide-volume-off',
  //       label: t('CONTACT_PANEL.MUTE_CONTACT'),
  //       action: 'mute',
  //       value: 'mute',
  //     });
  //   } else {
  //     items.push({
  //       icon: 'i-lucide-volume-1',
  //       label: t('CONTACT_PANEL.UNMUTE_CONTACT'),
  //       action: 'unmute',
  //       value: 'unmute',
  //     });
  //   }
  // }

  items.push({
    icon: 'i-lucide-share',
    label: t('CONTACT_PANEL.SEND_TRANSCRIPT'),
    action: 'send_transcript',
    value: 'send_transcript',
  });

  return items;
});

const handleActionClick = ({ action }) => {
  toggleDropdown(false);

  if (action === 'mute') {
    store.dispatch('muteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
  } else if (action === 'unmute') {
    store.dispatch('unmuteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
  } else if (action === 'send_transcript') {
    toggleEmailModal();
  }
};

// --- Mute/Unmute Event Listeners ---
const mute = () => {
  store.dispatch('muteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
};

const unmute = () => {
  store.dispatch('unmuteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
};

emitter.on(CMD_MUTE_CONVERSATION, mute);
emitter.on(CMD_UNMUTE_CONVERSATION, unmute);
emitter.on(CMD_SEND_TRANSCRIPT, toggleEmailModal);

onUnmounted(() => {
  emitter.off(CMD_MUTE_CONVERSATION, mute);
  emitter.off(CMD_UNMUTE_CONVERSATION, unmute);
  emitter.off(CMD_SEND_TRANSCRIPT, toggleEmailModal);
});

// --- Computed: Mostrar Resolve Button ---
const canShowResolveButton = computed(() => {
  return (
    userRole.value === 'administrator' ||
    (
      currentUser.value?.id === currentChat.value?.meta?.assignee?.id &&
      currentChat.value?.status !== 'resolved'
    )
  );
});

// --- Redirigir si NO puede ver el botón ---
watchEffect(() => {
  if (!canShowResolveButton.value && currentChat.value) {
    router.push(`/app/accounts/1/dashboard`);
  }
});

</script>

<template>
  <div class="relative flex items-center gap-2 actions--container">
    <ResolveAction
      v-if="canShowResolveButton"
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />

    <div
      v-on-clickaway="() => toggleDropdown(false)"
      class="relative flex items-center group"
    >
      <ButtonV4
        v-tooltip="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-more-vertical"
        class="rounded-md group-hover:bg-n-alpha-2"
        @click="toggleDropdown()"
      />
      <DropdownMenu
        v-if="showActionsDropdown"
        :menu-items="actionMenuItems"
        class="mt-1 ltr:right-0 rtl:left-0 top-full"
        @action="handleActionClick"
      />
    </div>

    <EmailTranscriptModal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailModal"
    />
  </div>
</template>
