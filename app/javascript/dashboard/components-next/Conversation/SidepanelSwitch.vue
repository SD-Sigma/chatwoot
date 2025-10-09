<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { computed } from 'vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

const { updateUISettings } = useUISettings();

// Detección de tema (usando color-scheme)
const theme = computed(() => {
  const html = document.documentElement;
  const scheme = html.style.colorScheme || html.getAttribute('style') || '';
  return scheme.includes('dark') ? 'dark' : 'light';
});

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCopilotTab = computed(() =>
  isFeatureEnabledonAccount.value(currentAccountId.value, FEATURE_FLAGS.CAPTAIN)
);

const { uiSettings } = useUISettings();
const isContactSidebarOpen = computed(
  () => uiSettings.value.is_contact_sidebar_open
);
const isCopilotPanelOpen = computed(
  () => uiSettings.value.is_copilot_panel_open
);


// 🎨 Variable con colores según tema y estado
const contactButtonStyle = computed(() => {
  const isLight = theme.value === 'light';
  const opened = isContactSidebarOpen.value;

  let baseColor, hoverColor, shadowColor;

  if (isLight) {
    baseColor = '#466525';
    hoverColor = '#627829';
    shadowColor = '#b6751a55';
  } else {
    baseColor = '#499643';
    hoverColor = '#1f6b90';
    shadowColor = '#26579955';
  }

  return {
    backgroundColor: opened ? baseColor : 'transparent',
    color: opened ? 'white' : baseColor,
    border: `1px solid ${baseColor}`,
    boxShadow: opened ? `0 0 6px ${shadowColor}` : 'none',
    transition: 'all 0.25s ease-in-out',
  };
});
const toggleConversationSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: !isContactSidebarOpen.value,
    is_copilot_panel_open: false,
  });
};

const handleConversationSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: true,
    is_copilot_panel_open: false,
  });
};

const handleCopilotSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: true,
  });
};

const keyboardEvents = {
  'Alt+KeyO': {
    action: toggleConversationSidebarToggle,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div
    class="flex flex-col justify-center items-center absolute top-36 xl:top-24 ltr:right-2 rtl:left-2 bg-n-solid-2 border border-n-weak rounded-full gap-2 p-1"
  >
    <Button
      v-tooltip.top="$t('CONVERSATION.SIDEBAR.CONTACT')"
      ghost
      slate
      sm
      :style="contactButtonStyle"
      class="!rounded-full"
      icon="i-ph-user-bold"
      @click="handleConversationSidebarToggle"
    />
    <Button
      v-if="showCopilotTab"
      v-tooltip.bottom="$t('CONVERSATION.SIDEBAR.COPILOT')"
      ghost
      slate
      class="!rounded-full text-[#265799] hover:bg-[#265799] hover:text-white transition-all"
      :class="{
        'bg-n-alpha-2 !text-n-iris-9': isCopilotPanelOpen,
      }"
      sm
      icon="i-woot-captain"
      @click="handleCopilotSidebarToggle"
    />
  </div>
</template>
